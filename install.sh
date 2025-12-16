#!/usr/bin/env bash

# Robustized install script
# - safer quoting
# - set -euo pipefail
# - better logging
# - DRY-RUN support
# - safer command runners

set -euo pipefail
IFS=$'\n\t'

# ---------------- Colors (guard tput availability) ----------------
if command -v tput >/dev/null 2>&1; then
  GREEN="$(tput setaf 2)"
  RED="$(tput setaf 1)"
  YELLOW="$(tput setaf 3)"
  CYAN="$(tput setaf 6)"
  NC="$(tput sgr0)"
else
  GREEN=""; RED=""; YELLOW=""; CYAN=""; NC=""
fi

FLAG_OK="[OK]"
FLAG_ERR="[ERROR]"
FLAG_NOTE="[NOTE]"
FLAG_ACTION="[ACTION]"

# ---------------- Paths & globals ----------------
CloneDir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG="${CloneDir}/install.log"
USERNAME="$(whoami)"

# ---------------- DRY-RUN ----------------
DRY_RUN=false
if [[ ${1-} == --dry-run ]]; then
  DRY_RUN=true
fi

# ---------------- Cleanup ----------------
TEMP_DIRS=()
cleanup() {
  local rc=$?
  for d in "${TEMP_DIRS[@]:-}"; do
    [[ -d "$d" ]] && rm -rf -- "$d" || true
  done
  exit "$rc"
}
trap cleanup EXIT

on_error() {
  local rc=$?
  printf "%s %s\n" "$RED$FLAG_ERR$NC" "Script failed (exit $rc). See $LOG for details." >&2
  [[ -f "$LOG" ]] && tail -n 50 "$LOG" >&2 || true
}
trap on_error ERR

# ---------------- Logging helpers ----------------
log() {
  local msg="$*"
  printf "%s [INFO] %s\n" "$(date +'%F %T')" "$msg" >>"$LOG"
}

print_error()   { printf "%s %s %s%s\n" "$RED"   "$FLAG_ERR"  "$1" "$NC" >&2; }
print_success() { printf "%s %s %s%s\n" "$GREEN" "$FLAG_OK"   "$1" "$NC"; }
print_note()    { printf "%s %s %s%s\n" "$YELLOW""$FLAG_NOTE" "$1" "$NC"; }
print_action()  { printf "%s %s %s%s\n" "$CYAN"  "$FLAG_ACTION" "$1" "$NC"; }

# ---------------- Command runners ----------------
run_cmd() {
  if $DRY_RUN; then
    print_note "[DRY-RUN] Would run: $*"
    return 0
  fi
  log "RUN: $*"
  "$@" 2>&1 | tee -a "$LOG"
}

run_pipe_cmd() {
  local cmd="$1"
  if $DRY_RUN; then
    print_note "[DRY-RUN] Would run pipeline: $cmd"
    return 0
  fi
  log "PIPE: $cmd"
  bash -c "$cmd" 2>&1 | tee -a "$LOG"
}

# ---------------- Privilege helpers ----------------
SUDO_CMD="sudo"
check_sudo() {
  if command -v doas >/dev/null 2>&1; then
    SUDO_CMD="doas"
  elif command -v sudo >/dev/null 2>&1; then
    SUDO_CMD="sudo"
  else
    print_error "Neither sudo nor doas found. Install one and re-run."
    exit 1
  fi
}

check_pacman_lock() {
  if [[ -e /var/lib/pacman/db.lck ]]; then
    print_error "Pacman database lock exists (/var/lib/pacman/db.lck)."
    print_note "If no pacman is running: sudo rm /var/lib/pacman/db.lck"
    exit 1
  fi
}

# ---------------- System update ----------------
update_system() {
  check_sudo
  check_pacman_lock
  print_action "Updating mirrors and system"

  if ! command -v reflector >/dev/null 2>&1; then
    run_cmd "$SUDO_CMD" pacman -S --noconfirm --needed reflector || true
  fi

  if command -v reflector >/dev/null 2>&1; then
    run_cmd "$SUDO_CMD" reflector --latest 10 --sort rate --save /etc/pacman.d/mirrorlist || true
  else
    print_note "reflector not available; skipping mirror optimization"
  fi

  run_cmd "$SUDO_CMD" pacman -Syu --noconfirm || true
  run_cmd "$SUDO_CMD" pacman -Fy || true
}

# ---------------- yay ----------------
check_and_install_yay() {
  if command -v yay >/dev/null 2>&1; then
    print_success "yay already installed"
    return 0
  fi

  print_action "Installing yay"
  run_cmd "$SUDO_CMD" pacman -S --noconfirm --needed git base-devel || true

  local tmpd
  tmpd="$(mktemp -d)"
  TEMP_DIRS+=("$tmpd")

  git clone https://aur.archlinux.org/yay.git "$tmpd/yay" 2>&1 | tee -a "$LOG"
  pushd "$tmpd/yay" >/dev/null

  if ! $DRY_RUN; then
    makepkg -si --noconfirm 2>&1 | tee -a "$LOG"
  else
    print_note "[DRY-RUN] Would run makepkg -si"
  fi

  popd >/dev/null
}

# ---------------- Packages ----------------
install_packages() {
  check_sudo
  check_pacman_lock

  local repo_pkgs=(base-devel git curl wget neovim vim tmux htop firefox networkmanager)
  print_action "Installing repo packages"
  run_cmd "$SUDO_CMD" pacman -S --noconfirm --needed "${repo_pkgs[@]}" || true

  if command -v yay >/dev/null 2>&1; then
    local aur_pkgs=(cursor-bin bibata-cursor-theme)
    print_action "Installing AUR packages"
    run_pipe_cmd "yay -S --noconfirm --needed ${aur_pkgs[*]}" || true
  fi
}

# ---------------- Main ----------------
main() {
  print_note "Starting install (DRY_RUN=$DRY_RUN)"
  log "Started by $USERNAME"

  check_sudo
  update_system
  check_and_install_yay
  install_packages

  print_success "Script completed successfully"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi
