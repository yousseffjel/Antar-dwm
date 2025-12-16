#!/usr/bin/env bash

Robustized install script

- safer quoting

- set -euo pipefail

- better logging

- DRY-RUN support

- safer command runners

set -euo pipefail IFS=$'\n\t'

Colors (guard tput availability)

if command -v tput >/dev/null 2>&1; then GREEN="$(tput setaf 2)" RED="$(tput setaf 1)" YELLOW="$(tput setaf 3)" CYAN="$(tput setaf 6)" NC="$(tput sgr0)" else GREEN="" RED="" YELLOW="" CYAN="" NC="" fi FLAG_OK="[OK]" FLAG_ERR="[ERROR]" FLAG_NOTE="[NOTE]" FLAG_ACTION="[ACTION]"

Determine script directory

CloneDir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)" LOG="${CloneDir}/install.log" USERNAME="$(whoami)"

DRY-RUN support

DRY_RUN=false if [[ ${1-} == --dry-run ]]; then DRY_RUN=true fi

Temp dirs cleanup

TEMP_DIRS=() cleanup() { local rc=$? for d in "${TEMP_DIRS[@]:-}"; do [[ -d "$d" ]] && rm -rf -- "$d" || true done exit $rc } trap cleanup EXIT

on_error() { local rc=$? printf "%s %s\n" "$RED$FLAG_ERR$NC" "Script failed (exit $rc). See $LOG for details." >&2

show last 50 lines of log if available

[[ -f "$LOG" ]] && tail -n 50 "$LOG" >&2 || true } trap on_error ERR

Logging helpers

log() { local msg="$*" printf "%s %s %s\n" "$(date +'%F %T')" "[INFO]" "$msg" >>"$LOG" }

print_error() { printf "%s %s%s%s\n" "$RED" "$FLAG_ERR" "$1" "$NC" >&2; } print_success() { printf "%s %s%s%s\n" "$GREEN" "$FLAG_OK" "$1" "$NC"; } print_note() { printf "%s %s%s%s\n" "$YELLOW" "$FLAG_NOTE" "$1" "$NC"; } print_action() { printf "%s %s%s%s\n" "$CYAN" "$FLAG_ACTION" "$1" "$NC"; }

Respect DRY_RUN and log output. Use this for simple commands (no shell pipelines)

run_cmd() { if $DRY_RUN; then print_note "[DRY-RUN] Would run: $" return 0 fi log "RUN: $"

run command and tee output to log

if "$@" 2>&1 | tee -a "$LOG"; then return 0 else return 1 fi }

Run a shell pipeline or complex shell string (single arg) safely in bash -c

run_pipe_cmd() { local cmd="$1" if $DRY_RUN; then print_note "[DRY-RUN] Would run pipeline: $cmd" return 0 fi log "PIPE: $cmd" if bash -c "$cmd" 2>&1 | tee -a "$LOG"; then return 0 else return 1 fi }

Check for sudo/doas

SUDO_CMD="sudo" check_sudo() { if command -v doas >/dev/null 2>&1; then SUDO_CMD="doas" elif command -v sudo >/dev/null 2>&1; then SUDO_CMD="sudo" else print_error "Neither sudo nor doas found. Please install one and re-run." exit 1 fi }

Check pacman lock

check_pacman_lock() { if [[ -e /var/lib/pacman/db.lck ]]; then print_error "Pacman database lock file exists (/var/lib/pacman/db.lck)." print_note "If no package manager is running, remove it with: sudo rm /var/lib/pacman/db.lck" exit 1 fi }

Update system and mirrors (reflector may not be installed on minimal systems)

update_system() { check_sudo check_pacman_lock print_action "Updating mirrors and system (reflector + pacman -Syu)" if ! command -v reflector >/dev/null 2>&1; then run_cmd $SUDO_CMD pacman -S --noconfirm --needed reflector || true fi if command -v reflector >/dev/null 2>&1; then run_cmd $SUDO_CMD reflector --verbose --latest 10 --sort rate --save /etc/pacman.d/mirrorlist || true else print_note "reflector not available; skipping mirror optimization" fi run_cmd $SUDO_CMD pacman -Syu --noconfirm || true

Update file database if desired

run_cmd $SUDO_CMD pacman -Fy || true }

Install yay (AUR helper) if missing

check_and_install_yay() { if command -v yay >/dev/null 2>&1; then print_success "yay already installed" return 0 fi print_action "Installing yay (AUR helper)" run_cmd $SUDO_CMD pacman -S --noconfirm --needed git base-devel || true local tmpd tmpd=$(mktemp -d) TEMP_DIRS+=("$tmpd") if ! git clone https://aur.archlinux.org/yay.git "$tmpd/yay" 2>&1 | tee -a "$LOG"; then print_error "Failed to clone yay repository" return 1 fi pushd "$tmpd/yay" >/dev/null

build as normal user

if $DRY_RUN; then print_note "[DRY-RUN] Would run makepkg -si --noconfirm" else if ! makepkg -si --noconfirm 2>&1 | tee -a "$LOG"; then print_error "makepkg failed while building yay" popd >/dev/null return 1 fi fi popd >/dev/null print_success "yay installation attempted (check log for details)" }

Install packages (reliable handling of arrays + logging)

install_packages() { check_sudo check_pacman_lock print_action "Installing official repo packages" local repo_pkgs=( base-devel libx11 libxft libxinerama freetype2 xorg-server sxhkd polkit-gnome ly thunar xcolor feh picom wget vim neovim tmux lxappearance network-manager-applet gvfs cpupower dunst libnotify xclip brightnessctl htop xdg-user-dirs pacman-contrib opendoas tar xsel curl tree binutils coreutils fuse2 alacritty fish fzf bat eza pv thunar-archive-plugin tumbler file-roller unzip unrar p7zip zip pipewire pipewire-pulse pipewire-alsa pipewire-jack wireplumber pamixer pavucontrol alsa-utils playerctl firefox copyq networkmanager xorg-xinit xorg-xrandr xorg-xsetroot xorg-xset xorg-xrdb rust ttf-jetbrains-mono-nerd papirus-icon-theme adwaita-icon-theme )

if ! run_cmd $SUDO_CMD pacman -S --noconfirm --needed "${repo_pkgs[@]}"; then print_error "Some official packages failed to install. Check $LOG" # continue - user may want to inspect fi

print_action "Installing AUR packages (via yay)" local aur_pkgs=( cursor-bin betterlockscreen xkblayout-state-git bibata-cursor-theme tela-circle-icon-theme-dracula catppuccin-gtk-theme-mocha catppuccin-gtk-theme-frappe st ) if command -v yay >/dev/null 2>&1; then if ! run_pipe_cmd "yay -S --noconfirm --needed --disable-download-timeout ${aur_pkgs[*]}"; then print_note "Some AUR packages failed to install; continuing" fi else print_note "yay not available; skipping AUR packages" fi

Optional AUR packages handled individually

local optional_pkgs=(stremio freedownloadmanager gruvbox-dark-gtk) for p in "${optional_pkgs[@]}"; do if command -v yay >/dev/null 2>&1; then set +e if run_pipe_cmd "yay -S --noconfirm $p"; then print_success "$p installed" else print_note "$p failed to install (optional)" fi set -e fi done

Update font cache

run_cmd fc-cache -vf || true run_cmd $SUDO_CMD fc-cache -vf || true run_cmd xdg-user-dirs-update || true print_success "Package installation step finished (see log for details)" }

Build suckless tools

build_suckless_tools() { print_action "Building suckless tools (dwm, dmenu, slstatus)" local SUCKLESS_DIR="" if [[ -d "$CloneDir/../suckless" ]]; then SUCKLESS_DIR="$CloneDir/../suckless" elif [[ -d "$HOME/dev/suckless" ]]; then SUCKLESS_DIR="$HOME/dev/suckless" else print_note "Suckless sources not found. Skipping build."; return 0 fi

for proj in dwm dmenu slstatus; do if [[ -d "$SUCKLESS_DIR/$proj" ]]; then pushd "$SUCKLESS_DIR/$proj" >/dev/null if [[ ! -f config.h || config.def.h -nt config.h ]]; then cp -f config.def.h config.h || true fi if make clean && make; then run_cmd $SUDO_CMD make install || true print_success "$proj built and installed" else print_error "Failed to build $proj" popd >/dev/null return 1 fi popd >/dev/null else print_note "$proj not present in $SUCKLESS_DIR" fi done }

Link configuration files (safe checks and creates backups)

link_config_files() { print_action "Linking configuration files" mkdir -p "$HOME/.config"

Helper: safe link function that backs up existing target

safe_link() { local src="$1" dst="$2" if [[ -e "$dst" && ! -L "$dst" ]]; then cp -a "$dst" "${dst}.backup-$(date +%s)" || true rm -rf -- "$dst" || true fi ln -sf -- "$src" "$dst" }

[[ -d "$CloneDir/dotconfig/sxhkd" ]] && safe_link "$CloneDir/dotconfig/sxhkd" "$HOME/.config/sxhkd" [[ -d "$CloneDir/dotconfig/betterlockscreen" ]] && safe_link "$CloneDir/dotconfig/betterlockscreen" "$HOME/.config/betterlockscreen" [[ -d "$CloneDir/dotconfig/dunst" ]] && safe_link "$CloneDir/dotconfig/dunst" "$HOME/.config/dunst" [[ -d "$CloneDir/dotconfig/picom" ]] && safe_link "$CloneDir/dotconfig/picom" "$HOME/.config/picom"

if [[ -d "$CloneDir/dotconfig/Cursor" ]]; then mkdir -p "$HOME/.config/Cursor/User" safe_link "$CloneDir/dotconfig/Cursor/User/settings.json" "$HOME/.config/Cursor/User/settings.json" || true fi

[[ -f "$CloneDir/dotconfig/.Xresources" ]] && safe_link "$CloneDir/dotconfig/.Xresources" "$HOME/.Xresources"

doas.conf handling

if [[ ! -f /etc/doas.conf ]]; then if [[ -f "$CloneDir/dotconfig/doas.conf" ]]; then local esc_user esc_user=$(printf '%s' "$USERNAME" | sed 's/[&\/]/\&/g') run_pipe_cmd "sed 's/USERNAME/$esc_user/g' '$CloneDir/dotconfig/doas.conf' | $SUDO_CMD tee /etc/doas.conf >/dev/null" print_success "doas.conf configured for $USERNAME" else run_pipe_cmd "echo 'permit persist $USERNAME as root' | $SUDO_CMD tee /etc/doas.conf >/dev/null" print_note "Created basic /etc/doas.conf" fi else print_note "/etc/doas.conf exists; not overwriting" fi

mkdir -p "$HOME/.config/tmux" [[ -f "$CloneDir/dotconfig/tmux/tmux.conf" ]] && safe_link "$CloneDir/dotconfig/tmux/tmux.conf" "$HOME/.config/tmux/tmux.conf" [[ -f "$CloneDir/dotconfig/tmux/tmux.reset.conf" ]] && safe_link "$CloneDir/dotconfig/tmux/tmux.reset.conf" "$HOME/.config/tmux/tmux.reset.conf"

tmux plugin manager

if [[ ! -d "$HOME/.tmux/plugins/tpm" ]]; then if ! run_pipe_cmd "git clone https://github.com/tmux-plugins/tpm '$HOME/.tmux/plugins/tpm'"; then print_note "Failed to clone tpm; you may install it manually" fi fi

if [[ -d "$CloneDir/scripts" ]]; then mkdir -p "$HOME/src/bin" if compgen -G "$CloneDir/scripts/" >/dev/null; then cp -r "$CloneDir/scripts"/ "$HOME/src/bin/" if compgen -G "$HOME/src/bin/.sh" >/dev/null; then chmod +x "$HOME/src/bin"/.sh || true fi print_success "Helper scripts installed to ~/src/bin" fi fi

if [[ -f "$CloneDir/dotconfig/autostart.sh" ]]; then mkdir -p "$HOME/.config/dwm" safe_link "$CloneDir/dotconfig/autostart.sh" "$HOME/.config/dwm/autostart.sh" chmod +x "$HOME/.config/dwm/autostart.sh" || true fi

[[ -f "$CloneDir/dotconfig/helpers.rc" ]] && safe_link "$CloneDir/dotconfig/helpers.rc" "$HOME/.config/helpers.rc" || true [[ -d "$CloneDir/dotconfig/alacritty" ]] && safe_link "$CloneDir/dotconfig/alacritty" "$HOME/.config/alacritty" && print_success "Alacritty linked"

if [[ -f "$CloneDir/dotconfig/git/config" ]]; then mkdir -p "$HOME/.config/git" safe_link "$CloneDir/dotconfig/git/config" "$HOME/.config/git/config" fi [[ -d "$CloneDir/dotconfig/nvim" ]] && safe_link "$CloneDir/dotconfig/nvim" "$HOME/.config/nvim" && print_success "Neovim linked"

if [[ -f "$CloneDir/dotconfig/dwm.desktop" ]]; then run_cmd $SUDO_CMD mkdir -p /usr/share/xsessions run_cmd $SUDO_CMD cp -f "$CloneDir/dotconfig/dwm.desktop" /usr/share/xsessions/dwm.desktop || true fi

mkdir -p "$HOME/Pictures/Screenshots" "$HOME/mnt" print_success "Config linking completed" }

Install Cursor extensions (if cursor CLI is available)

install_cursor_extensions() { local cursor_cmd="" if command -v cursor >/dev/null 2>&1; then cursor_cmd="cursor"; elif command -v cursor-editor >/dev/null 2>&1; then cursor_cmd="cursor-editor"; fi if [[ -z "$cursor_cmd" ]]; then print_note "Cursor CLI not found; skipping extensions" return 0 fi

local extensions=( anysphere.cursorpyright bradlc.vscode-tailwindcss charliermarsh.ruff christian-kohler.path-intellisense dbaeumer.vscode-eslint eamodio.gitlens editorconfig.editorconfig esbenp.prettier-vscode graphql.vscode-graphql mikestead.dotenv ms-azuretools.vscode-docker ms-python.python redhat.vscode-yaml rphlmr.vscode-drizzle-orm typescriptteam.native-preview usernamehw.errorlens )

for ext in "${extensions[@]}"; do print_note "Installing $ext" run_pipe_cmd "$cursor_cmd --install-extension '$ext'" || print_note "Failed to install $ext" done print_success "Cursor extensions step completed" }

Optional bluetooth installation

install_bluetooth() { if [[ ! -t 0 ]]; then print_note "Non-interactive; skipping Bluetooth setup" return 0 fi read -r -p "${FLAG_ACTION} OPTIONAL - Install Bluetooth packages? (y/N): " ans if [[ $ans =~ ^[Yy]$ ]]; then print_action "Installing Bluetooth packages" local blue_pkgs=(bluez bluez-utils blueman) if command -v yay >/dev/null 2>&1; then run_pipe_cmd "yay -S --noconfirm --needed ${blue_pkgs[*]}" || print_note "Bluetooth AUR package install had issues" else run_cmd $SUDO_CMD pacman -S --noconfirm --needed "${blue_pkgs[@]}" || print_note "Bluetooth repo package install had issues" fi run_cmd $SUDO_CMD systemctl enable --now bluetooth.service || true if systemctl is-active --quiet bluetooth.service; then print_success "Bluetooth service is active" else print_note "Bluetooth service not active; check output" fi else print_note "Bluetooth installation skipped" fi }

Power management placeholder (keeps function short)

setup_power_management() { print_note "Power management configuration skipped by default. Customize as needed." }

Main

main() { print_note "Starting install script (DRY_RUN=${DRY_RUN})" log "Script started by $USERNAME" check_sudo update_system check_and_install_yay install_packages build_suckless_tools link_config_files install_cursor_extensions install_bluetooth setup_power_management print_success "Script completed (check $LOG for detailed output)" }

If sourced, don't run main automatically

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then main "$@" fi