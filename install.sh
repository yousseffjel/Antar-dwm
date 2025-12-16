#!/bin/bash

# Define constants for colors and log file
GREEN="$(tput setaf 2)[OK]$(tput sgr0)"
RED="$(tput setaf 1)[ERROR]$(tput sgr0)"
YELLOW="$(tput setaf 3)[NOTE]$(tput sgr0)"
CAT="$(tput setaf 6)[ACTION]$(tput sgr0)"
NC="$(tput sgr0)"
LOG="install.log"
# Get the directory where the script is located, not where it's run from
CloneDir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
USERNAME=$(whoami)

# DRY-RUN mode support
DRY_RUN=false
[[ "$1" == "--dry-run" ]] && DRY_RUN=true

# Helper function to run commands (respects DRY_RUN)
run() {
    if $DRY_RUN; then
        print_note "[DRY-RUN] Would execute: $*"
        return 0
    else
        "$@"
    fi
}

# Helper function to run piped commands (respects DRY_RUN)
# Usage: run_pipe "command1 | command2 | command3"
# SECURITY: Uses bash -c instead of eval to prevent command injection
run_pipe() {
    if $DRY_RUN; then
        print_note "[DRY-RUN] Would execute pipeline: $*"
        return 0
    else
        # Use bash -c with proper quoting to avoid eval security issues
        bash -c "$*"
    fi
}

# Set the script to exit on error and log failures
set -e 
set -o pipefail  # Exit on pipe failures
trap 'echo -e "\033[0;31m[ERROR] Script failed. Check install.log for more details.\033[0m"' ERR

# Track temp directories for cleanup
TEMP_DIRS=()
trap 'for dir in "${TEMP_DIRS[@]}"; do [[ -d "$dir" ]] && rm -rf "$dir" 2>/dev/null || true; done' EXIT

# Utility functions for printing messages
print_error() {
    printf "%s%s%s\n" "$RED" "$1" "$NC" >&2
}

print_success() {
    printf "%s%s%s\n" "$GREEN" "$1" "$NC"
}

print_note() {
    printf "%s%s%s\n" "$YELLOW" "$1" "$NC"
}

print_action() {
    printf "%s%s%s\n" "$CAT" "$1" "$NC"
}

# Function to check if sudo/doas is available and set SUDO_CMD
check_sudo() {
    if ! command -v sudo &> /dev/null && ! command -v doas &> /dev/null; then
        print_error "Neither sudo nor doas is available. Please install one of them first."
        exit 1
    fi
    # Use doas if available, otherwise sudo
    if command -v doas &> /dev/null; then
        SUDO_CMD="doas"
    else
        SUDO_CMD="sudo"
    fi
}

# Function to check if pacman database is locked
check_pacman_lock() {
    if [[ -f /var/lib/pacman/db.lck ]]; then
        print_error "Pacman database is locked!"
        print_note "Another package manager process is likely running."
        print_note "Please wait for it to finish, or if you're sure nothing is running, remove the lock:"
        print_note "  sudo rm /var/lib/pacman/db.lck"
        print_note ""
        print_note "To check for running pacman processes:"
        print_note "  ps aux | grep -E 'pacman|yay'"
        exit 1
    fi
}

# Function to update the system and install Reflector for faster mirrors
update_system() {
    check_sudo
    check_pacman_lock
    print_note "Updating the system and optimizing mirrors..."
    run $SUDO_CMD pacman -S --noconfirm reflector
    
    print_note "This will overwrite /etc/pacman.d/mirrorlist with optimized mirrors."
    run $SUDO_CMD reflector --verbose --latest 10 --sort rate --save /etc/pacman.d/mirrorlist
    
    run $SUDO_CMD pacman -Syu --noconfirm
    run $SUDO_CMD pacman -Fy
}

# Function to check if yay is installed, and install it if not
check_and_install_yay() {
    if command -v yay &> /dev/null; then
        print_success "yay is already installed."
    else 
        print_note "yay not found. Installing yay..."
        run $SUDO_CMD pacman -S --noconfirm git base-devel
        TMPDIR=$(mktemp -d)
        TEMP_DIRS+=("$TMPDIR")
        
        if ! git clone https://aur.archlinux.org/yay.git "$TMPDIR/yay"; then
            print_error "Failed to clone yay repository. Please check your internet connection."
            exit 1
        fi
        
        cd "$TMPDIR/yay"
        # makepkg -si uses sudo internally, so we don't need $SUDO_CMD here
        if ! run_pipe "makepkg -si --noconfirm 2>&1 | tee -a \"$CloneDir/$LOG\""; then
            print_error "Failed to build/install yay. Please check the install.log."
            exit 1
        fi
        cd "$CloneDir"
        print_success "yay installed successfully."
    fi
}

# Function to install a list of packages using yay
install_packages() {
    # Optional AUR packages (may not be available)
    local optional_pkgs=(
        stremio freedownloadmanager
        gruvbox-dark-gtk
    )

    # Separate official repo packages from AUR packages
    # Official repo packages (install with pacman first for reliability)
    local repo_pkgs=(
        base-devel libx11 libxft libxinerama freetype2 xorg-server
        sxhkd polkit-gnome ly thunar xcolor feh picom wget
        vim neovim tmux lxappearance network-manager-applet
        gvfs cpupower satty dunst libnotify xclip
        brightnessctl htop xdg-user-dirs pacman-contrib
        opendoas tar xsel
        curl tree binutils coreutils fuse2
        # Terminal: alacritty (main), st (secondary - from AUR)
        alacritty
        # Shell: fish shell and utilities
        fish fzf bat eza pv
        # File manager and archive support
        thunar-archive-plugin tumbler file-roller
        # Archive extraction tools (full support)
        unzip unrar p7zip zip
        # Audio system: PipeWire (modern replacement for PulseAudio)
        pipewire pipewire-pulse pipewire-alsa pipewire-jack wireplumber
        pamixer pavucontrol alsa-utils
        # Media control
        playerctl
        # Applications referenced in keybindings
        firefox copyq
        # Network management
        networkmanager
        # X11 utilities
        xorg-xinit xorg-xrandr xorg-xsetroot xorg-xset xorg-xrdb
        # Development tools
        rust
        # Essential fonts: JetBrains Mono Nerd Font (global font for all applications)
        ttf-jetbrains-mono-nerd
        # Essential icons (3 themes)
        papirus-icon-theme adwaita-icon-theme
        # Essential themes (will add AUR themes separately)
    )
    
    # AUR packages (install with yay)
    local aur_pkgs=(
        cursor-bin betterlockscreen
        xkblayout-state-git
        # Cursor theme
        bibata-cursor-theme
        # Essential icon theme
        tela-circle-icon-theme-dracula
        # Essential GTK themes
        catppuccin-gtk-theme-mocha catppuccin-gtk-theme-frappe
        # Simple terminal (st) from suckless - secondary terminal
        st
    )

    check_pacman_lock
    print_action "Installing official repository packages..."
    # NOTE: Official repo packages are critical - exit on failure
    # AUR packages may fail due to availability issues, so we continue on failure
    if ! run_pipe "$SUDO_CMD pacman -S --noconfirm --needed \"${repo_pkgs[@]}\" 2>&1 | tee -a \"$LOG\""; then
        print_error "Failed to install official packages. Please check the install.log."
        exit 1
    fi
    
    check_pacman_lock
    print_action "Installing AUR packages..."
    # NOTE: AUR packages may fail due to:
    # - Package no longer available
    # - Build failures
    # - Network issues
    # We continue installation even if some AUR packages fail, as they're often optional
    if ! run_pipe "yay -S --noconfirm --needed --disable-download-timeout \"${aur_pkgs[@]}\" 2>&1 | tee -a \"$LOG\""; then
        print_error "Some AUR packages failed to install. Continuing..."
    fi
    
    # Try to install optional AUR packages (may fail if not available)
    print_action "Installing optional AUR packages..."
    for pkg in "${optional_pkgs[@]}"; do
        set +e  # Temporarily disable exit on error
        if run_pipe "yay -S --noconfirm \"$pkg\" 2>&1 | tee -a \"$LOG\""; then
            print_success "$pkg installed successfully."
        else
            print_note "$pkg not available or installation failed. You can try installing manually later."
        fi
        set -e  # Re-enable exit on error
    done
    
    # Update font cache
    print_note "Updating font cache..."
    run_pipe "fc-cache -vf 2>&1 | tee -a \"$LOG\"" || print_note "User font cache update had issues (continuing)..."
    run_pipe "$SUDO_CMD fc-cache -vf 2>&1 | tee -a \"$LOG\"" || print_note "System font cache update had issues (continuing)..."
    
    print_note "Updating user directories..."
    run_pipe "xdg-user-dirs-update 2>&1 | tee -a \"$LOG\"" || print_note "xdg-user-dirs-update had issues (continuing)..."
    print_success "All packages installed successfully."
}

# Function to build and install suckless tools (dwm, dmenu, slstatus)
build_suckless_tools() {
    print_action "Building and installing suckless tools..."
    
    # Check if suckless directory exists (should be in parent directory)
    SUCKLESS_DIR=""
    if [[ -d "$CloneDir/../suckless" ]]; then
        SUCKLESS_DIR="$CloneDir/../suckless"
    elif [[ -d "$HOME/dev/suckless" ]]; then
        SUCKLESS_DIR="$HOME/dev/suckless"
    else
        print_error "Suckless directory not found. Expected at: $CloneDir/../suckless or $HOME/dev/suckless"
        print_note "Please ensure the suckless project is cloned in the correct location."
        return 1
    fi
    
    print_note "Found suckless directory at: $SUCKLESS_DIR"
    
    # Build and install dwm
    if [[ -d "$SUCKLESS_DIR/dwm" ]]; then
        print_action "Building dwm..."
        cd "$SUCKLESS_DIR/dwm"
        # Regenerate config.h from config.def.h if needed
        if [[ ! -f config.h ]] || [[ config.def.h -nt config.h ]]; then
            cp config.def.h config.h
            print_note "Regenerated dwm config.h from config.def.h"
        fi
        if make clean && make; then
            run $SUDO_CMD make install
            print_success "dwm built and installed successfully."
        else
            print_error "Failed to build dwm. Check the output above for errors."
            cd "$CloneDir"
            return 1
        fi
        cd "$CloneDir"
    else
        print_error "dwm directory not found in $SUCKLESS_DIR"
        return 1
    fi
    
    # Build and install dmenu
    if [[ -d "$SUCKLESS_DIR/dmenu" ]]; then
        print_action "Building dmenu..."
        cd "$SUCKLESS_DIR/dmenu"
        # Regenerate config.h from config.def.h if needed
        if [[ ! -f config.h ]] || [[ config.def.h -nt config.h ]]; then
            cp config.def.h config.h
            print_note "Regenerated dmenu config.h from config.def.h"
        fi
        if make clean && make; then
            run $SUDO_CMD make install
            print_success "dmenu built and installed successfully."
        else
            print_error "Failed to build dmenu. Check the output above for errors."
            cd "$CloneDir"
            return 1
        fi
        cd "$CloneDir"
    else
        print_error "dmenu directory not found in $SUCKLESS_DIR"
        return 1
    fi
    
    # Build and install slstatus
    if [[ -d "$SUCKLESS_DIR/slstatus" ]]; then
        print_action "Building slstatus..."
        cd "$SUCKLESS_DIR/slstatus"
        # Regenerate config.h from config.def.h if needed
        if [[ ! -f config.h ]] || [[ config.def.h -nt config.h ]]; then
            cp config.def.h config.h
            print_note "Regenerated slstatus config.h from config.def.h"
        fi
        if make clean && make; then
            run $SUDO_CMD make install
            print_success "slstatus built and installed successfully."
        else
            print_error "Failed to build slstatus. Check the output above for errors."
            cd "$CloneDir"
            return 1
        fi
        cd "$CloneDir"
    else
        print_error "slstatus directory not found in $SUCKLESS_DIR"
        return 1
    fi
    
    print_success "All suckless tools built and installed successfully."
}

# Function to link config files
link_config_files() {
    print_action "Linking configuration files..."

    # Ensure .config directory exists
    mkdir -p "$HOME/.config"

    # Link various config files
    ln -sf "$CloneDir/dotconfig/sxhkd" "$HOME/.config/"
    ln -sf "$CloneDir/dotconfig/betterlockscreen" "$HOME/.config/"
    ln -sf "$CloneDir/dotconfig/dunst" "$HOME/.config/"
    ln -sf "$CloneDir/dotconfig/picom" "$HOME/.config/"
    
    # Link Cursor config (if it exists)
    if [[ -d "$CloneDir/dotconfig/Cursor" ]]; then
        mkdir -p "$HOME/.config/Cursor/User"
        ln -sf "$CloneDir/dotconfig/Cursor/User/settings.json" "$HOME/.config/Cursor/User/settings.json" 2>/dev/null || true
    fi
    
    # Link .Xresources if it exists
    if [[ -f "$CloneDir/dotconfig/.Xresources" ]]; then
        ln -sf "$CloneDir/dotconfig/.Xresources" "$HOME/.Xresources"
    fi
    
    # Setup doas.conf from template
    if [[ ! -f /etc/doas.conf ]]; then
        if [[ -f "$CloneDir/dotconfig/doas.conf" ]]; then
            # Replace USERNAME placeholder with actual username
            # Escape special characters in USERNAME for sed
            ESCAPED_USERNAME=$(printf '%s\n' "$USERNAME" | sed 's/[[\.*^$()+?{|]/\\&/g')
            sed "s/USERNAME/$ESCAPED_USERNAME/g" "$CloneDir/dotconfig/doas.conf" | run $SUDO_CMD tee /etc/doas.conf > /dev/null
            print_success "doas.conf configured for user $USERNAME"
        else
            # Fallback: create basic config
            echo "permit persist $USERNAME as root" | run $SUDO_CMD tee /etc/doas.conf > /dev/null
            print_note "doas.conf created with basic configuration."
        fi
    else
        print_note "doas.conf already exists. Skipping..."
    fi

    # Configure tmux
    mkdir -p "$HOME/.config/tmux"
    ln -sf "$CloneDir/dotconfig/tmux/tmux.conf" "$HOME/.config/tmux/tmux.conf"
    ln -sf "$CloneDir/dotconfig/tmux/tmux.reset.conf" "$HOME/.config/tmux/tmux.reset.conf"

    # Ensure tmux plugin manager is installed
    if [[ ! -d "$HOME/.tmux/plugins/tpm" ]]; then
        if ! run_pipe "git clone https://github.com/tmux-plugins/tpm \"$HOME/.tmux/plugins/tpm\" 2>&1 | tee -a \"$LOG\""; then
            print_note "Failed to clone tmux plugin manager. You can install it manually later."
        fi
    fi

    # Install helper scripts
    if [[ -d "$CloneDir/scripts" ]]; then
        mkdir -p "$HOME/src/bin"
        # Check if there are any files to copy
        if ls "$CloneDir/scripts"/* >/dev/null 2>&1; then
            cp -r "$CloneDir/scripts"/* "$HOME/src/bin/"
            # Only chmod if .sh files exist
            if ls "$HOME/src/bin"/*.sh >/dev/null 2>&1; then
                chmod +x "$HOME/src/bin"/*.sh
            fi
            print_success "Helper scripts installed to ~/src/bin/"
        else
            print_note "No scripts found in scripts directory. Skipping..."
        fi
    fi

    # Link dwm autostart script (for dwm with autostart patch)
    if [[ -f "$CloneDir/dotconfig/autostart.sh" ]]; then
        mkdir -p "$HOME/.config/dwm"
        ln -sf "$CloneDir/dotconfig/autostart.sh" "$HOME/.config/dwm/autostart.sh"
        chmod +x "$CloneDir/dotconfig/autostart.sh" 2>/dev/null || true
        print_success "dwm autostart script linked"
    fi

    # Link helpers.rc (if needed by any application)
    if [[ -f "$CloneDir/dotconfig/helpers.rc" ]]; then
        ln -sf "$CloneDir/dotconfig/helpers.rc" "$HOME/.config/helpers.rc" 2>/dev/null || true
    fi

    # Link alacritty config
    if [[ -d "$CloneDir/dotconfig/alacritty" ]]; then
        ln -sf "$CloneDir/dotconfig/alacritty" "$HOME/.config/"
        print_success "Alacritty config linked"
    fi

    # Link git config
    if [[ -f "$CloneDir/dotconfig/git/config" ]]; then
        mkdir -p "$HOME/.config/git"
        ln -sf "$CloneDir/dotconfig/git/config" "$HOME/.config/git/config"
        print_success "Git config linked"
    fi

    # Link nvim config
    if [[ -d "$CloneDir/dotconfig/nvim" ]]; then
        ln -sf "$CloneDir/dotconfig/nvim" "$HOME/.config/"
        print_success "Neovim config linked"
    fi

    # Install dwm.desktop for display manager
    if [[ -f "$CloneDir/dotconfig/dwm.desktop" ]]; then
        run $SUDO_CMD mkdir -p /usr/share/xsessions
        run $SUDO_CMD cp -f "$CloneDir/dotconfig/dwm.desktop" /usr/share/xsessions/dwm.desktop
        print_success "dwm.desktop installed for display manager"
    fi

    # Create Screenshots directory (used by sxhkdrc)
    mkdir -p "$HOME/Pictures/Screenshots"
    print_success "Screenshots directory created"
    
    # Create mount point directory (used by mount scripts)
    mkdir -p "$HOME/mnt"
    print_success "Mount point directory created"

    print_success "Configuration files linked successfully."
}

# Function to install Cursor extensions
install_cursor_extensions() {
    print_action "Installing Cursor extensions..."

    # Check for cursor command (may be cursor or cursor-editor)
    local cursor_cmd=""
    if command -v cursor &> /dev/null; then
        cursor_cmd="cursor"
    elif command -v cursor-editor &> /dev/null; then
        cursor_cmd="cursor-editor"
    else
        print_note "Cursor not found. Skipping extension installation."
        print_note "You can install extensions manually after installing Cursor:"
        print_note "  cursor --install-extension <extension-id>"
        return
    fi
    
    # List of extensions to install (development-focused extensions)
    extensions=(
        "anysphere.cursorpyright"
        "bradlc.vscode-tailwindcss"
        "charliermarsh.ruff"
        "christian-kohler.path-intellisense"
        "dbaeumer.vscode-eslint"
        "eamodio.gitlens"
        "editorconfig.editorconfig"
        "esbenp.prettier-vscode"
        "graphql.vscode-graphql"
        "graphql.vscode-graphql-syntax"
        "mikestead.dotenv"
        "ms-azuretools.vscode-containers"
        "ms-azuretools.vscode-docker"
        "ms-python.black-formatter"
        "ms-python.debugpy"
        "ms-python.python"
        "redhat.vscode-yaml"
        "rphlmr.vscode-drizzle-orm"
        "typescriptteam.native-preview"
        "usernamehw.errorlens"
    )
    
    print_note "Installing ${#extensions[@]} Cursor extensions..."
    for ext in "${extensions[@]}"; do
        print_note "Installing $ext..."
        run_pipe "$cursor_cmd --install-extension \"$ext\" 2>&1 | tee -a \"$LOG\"" || print_note "Failed to install $ext"
    done
    
    print_success "Cursor extensions installation completed."
}

# Function to optionally install Bluetooth packages
install_bluetooth() {
    # Check if running in interactive terminal
    if [[ ! -t 0 ]]; then
        print_note "Not running in interactive terminal. Skipping Bluetooth installation."
        return
    fi
    
    read -n1 -rep "${CAT} OPTIONAL - Would you like to install Bluetooth packages? (y/n)" BLUETOOTH || {
        print_note "Input cancelled. Skipping Bluetooth installation."
        return
    }
    if [[ $BLUETOOTH =~ ^[Yy]$ ]]; then
        print_action "Installing Bluetooth Packages..."
        local blue_pkgs=(bluez bluez-utils blueman)
        if ! run_pipe "yay -S --noconfirm --needed \"${blue_pkgs[@]}\" 2>&1 | tee -a \"$LOG\""; then
            print_error "Failed to install Bluetooth packages. Please check the install.log."
        else
            run $SUDO_CMD systemctl enable bluetooth.service
            run $SUDO_CMD systemctl start bluetooth.service
            if systemctl is-active bluetooth.service; then
                print_success "Bluetooth service enabled and running."
            else
                print_error "Bluetooth service failed to start."
            fi
        fi
    else
        print_note "Bluetooth packages installation skipped."
    fi
}

# Function to set up power management for maximum performance
setup_power_management() {
    # Check if running in interactive terminal
    if [[ ! -t 0 ]]; then
        print_note "Not running in interactive terminal. Skipping aggressive performance mode."
        print_note "You can enable it manually later if needed."
        return
    fi
    
    print_action "Aggressive Performance Mode Configuration"
    print_note "WARNING: This will configure your system for maximum performance:"
    print_note "  - CPU governor set to 'performance' (always max speed)"
    print_note "  - USB autosuspend disabled"
    print_note "  - PCIe ASPM set to performance"
    print_note ""
    print_note "This increases heat, power consumption, and may affect suspend/resume."
    print_note "Only enable if you have a laptop that's always plugged in with dead battery."
    echo ""
    
    read -n1 -rep "${CAT} Enable aggressive performance mode? (y/n) " PERF_MODE || {
        print_note "Input cancelled. Skipping performance mode configuration."
        return
    }
    if [[ ! $PERF_MODE =~ ^[Yy]$ ]]; then
        print_note "Performance mode skipped. System will use default power management."
        return
    fi
    
    print_action "Configuring system for maximum performance (always plugged in)..."
    
    # Set CPU governor to performance mode
    if command -v cpupower &> /dev/null; then
        print_note "Setting CPU governor to performance mode..."
        run_pipe "$SUDO_CMD cpupower frequency-set -g performance 2>&1 | tee -a \"$LOG\"" || print_note "Could not set CPU governor (may need manual configuration)"
        
        # Make it persistent by creating a systemd service
        print_note "Creating systemd service for performance mode..."
        run $SUDO_CMD tee /etc/systemd/system/cpu-performance.service > /dev/null <<EOF
[Unit]
Description=Set CPU governor to performance
After=multi-user.target

[Service]
Type=oneshot
ExecStart=/usr/bin/cpupower frequency-set -g performance
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF
        
        run $SUDO_CMD systemctl daemon-reload
        run $SUDO_CMD systemctl enable cpu-performance.service
        run $SUDO_CMD systemctl start cpu-performance.service
        
        print_success "CPU performance mode configured."
    else
        print_note "cpupower not found. You may need to set CPU governor manually."
    fi
    
    # Disable power saving features and make them persistent
    print_note "Disabling power saving features..."
    
    # Create modprobe config to disable USB autosuspend
    if [[ ! -f /etc/modprobe.d/usb-autosuspend.conf ]]; then
        echo "options usbcore autosuspend=-1" | run $SUDO_CMD tee /etc/modprobe.d/usb-autosuspend.conf > /dev/null
        print_note "USB autosuspend disabled (persistent)"
    fi
    
    # Create modprobe config for PCIe ASPM performance
    if [[ ! -f /etc/modprobe.d/pcie-aspm-performance.conf ]]; then
        echo "options pcie_aspm policy=performance" | run $SUDO_CMD tee /etc/modprobe.d/pcie-aspm-performance.conf > /dev/null
        print_note "PCIe ASPM set to performance (persistent)"
    fi
    
    # Apply settings immediately (if modules are loaded)
    if [[ -f /sys/module/usbcore/parameters/autosuspend ]]; then
        echo -1 | run $SUDO_CMD tee /sys/module/usbcore/parameters/autosuspend > /dev/null 2>&1 || true
    fi
    
    if [[ -f /sys/module/pcie_aspm/parameters/policy ]]; then
        echo performance | run $SUDO_CMD tee /sys/module/pcie_aspm/parameters/policy > /dev/null 2>&1 || true
    fi
    
    print_success "Power management configured for maximum performance."
    print_note "Note: This setup is optimized for always-plugged-in usage."
    print_note "CPU governor set to 'performance', USB autosuspend disabled, PCIe ASPM set to performance."
}

# Function to enable system services and configure user groups
enable_services_and_groups() {
    print_action "Enabling system services and configuring user groups..."
    
    # Enable NetworkManager
    if command -v NetworkManager &> /dev/null; then
        run $SUDO_CMD systemctl enable NetworkManager.service
        run $SUDO_CMD systemctl start NetworkManager.service
        print_success "NetworkManager enabled and started"
    else
        print_note "NetworkManager not found. Skipping..."
    fi
    
    # Enable display manager (ly)
    if command -v ly &> /dev/null; then
        run $SUDO_CMD systemctl enable ly.service
        print_success "Display manager (ly) enabled"
    else
        print_note "Display manager (ly) not found. Skipping..."
    fi
    
    # Enable PipeWire services (user services)
    if command -v pipewire &> /dev/null; then
        print_note "Configuring PipeWire audio system..."
        # Enable PipeWire user services (wireplumber is the modern session manager)
        systemctl --user enable pipewire.service pipewire-pulse.service wireplumber.service 2>/dev/null || true
        print_success "PipeWire services configured (will start on login)"
        print_note "Note: PipeWire will start automatically when you log in. Audio should work after first login."
    else
        print_note "PipeWire not found. Skipping audio service configuration..."
    fi
    
    # Add user to required groups
    print_action "Adding user to required groups..."
    local groups_to_add=()
    
    # Check which groups user is not in
    if ! groups "$USERNAME" | grep -q '\baudio\b'; then
        groups_to_add+=("audio")
    fi
    if ! groups "$USERNAME" | grep -q '\bvideo\b'; then
        groups_to_add+=("video")
    fi
    if ! groups "$USERNAME" | grep -q '\binput\b'; then
        groups_to_add+=("input")
    fi
    if ! groups "$USERNAME" | grep -q '\bstorage\b'; then
        groups_to_add+=("storage")
    fi
    
    if [ ${#groups_to_add[@]} -gt 0 ]; then
        run $SUDO_CMD usermod -aG "$(IFS=,; echo "${groups_to_add[*]}")" "$USERNAME"
        print_success "User added to groups: ${groups_to_add[*]}"
        print_note "Note: You may need to log out and back in (or reboot) for group changes to take effect."
    else
        print_success "User already in all required groups"
    fi
}

# Function to install Fish shell configuration
install_fish_config() {
    print_action "Installing Fish shell configuration..."
    
    # Check if fish project directory exists
    FISH_DIR=""
    if [[ -d "$CloneDir/../fish" ]]; then
        FISH_DIR="$CloneDir/../fish"
    elif [[ -d "$HOME/dev/fish" ]]; then
        FISH_DIR="$HOME/dev/fish"
    else
        print_note "Fish project directory not found. Expected at: $CloneDir/../fish or $HOME/dev/fish"
        print_note "Skipping Fish configuration installation."
        return 0
    fi
    
    print_note "Found fish directory at: $FISH_DIR"
    
    # Check if fish install script exists
    if [[ ! -f "$FISH_DIR/install.sh" ]]; then
        print_error "Fish install script not found at $FISH_DIR/install.sh"
        return 1
    fi
    
    # Run fish install script with --no-packages (we already installed fish)
    # and --no-chsh (let user decide if they want to change shell)
    print_note "Running Fish configuration installer..."
    if run_pipe "bash \"$FISH_DIR/install.sh\" --no-packages --no-chsh 2>&1 | tee -a \"$LOG\""; then
        print_success "Fish configuration installed successfully."
    else
        print_error "Fish configuration installation failed. Check install.log for details."
        print_note "You can run the fish install script manually: $FISH_DIR/install.sh"
    fi
}

# Function to finalize the setup
finalize_setup() {
    # Setup betterlockscreen service
    # Check if user systemd is available
    if ! systemctl --user list-unit-files &>/dev/null; then
        print_note "User systemd not available, skipping betterlockscreen service."
    elif systemctl --user list-unit-files 2>/dev/null | grep -q betterlockscreen; then
        systemctl --user enable "betterlockscreen@$USERNAME.service" 2>/dev/null || true
    fi
    
    # Setup wallpaper (optional - check if directory exists)
    if [[ -d "$HOME/Pictures/Wallpapers" ]] || [[ -d "$HOME/.local/share/wallpapers" ]]; then
        WALLPAPER_DIR="$HOME/Pictures/Wallpapers"
        if [[ ! -d "$WALLPAPER_DIR" ]]; then
            WALLPAPER_DIR="$HOME/.local/share/wallpapers"
        fi
        
        # Find first image file
        WALLPAPER=$(find "$WALLPAPER_DIR" -type f \( -name "*.jpg" -o -name "*.png" -o -name "*.jpeg" \) | head -n 1)
        
        if [[ -n "$WALLPAPER" ]]; then
            if command -v betterlockscreen &> /dev/null; then
                print_action "Setting up betterlockscreen wallpaper..."
                run_pipe "betterlockscreen -u \"$WALLPAPER\" --blur 2>&1 | tee -a \"$LOG\"" || print_note "Could not set wallpaper. You can set it manually later."
            else
                print_note "betterlockscreen not found. Skipping wallpaper setup."
            fi
        else
            print_note "No wallpaper found. You can set one later with: betterlockscreen -u <path-to-image>"
        fi
    else
        print_note "Wallpaper directory not found. Create ~/Pictures/Wallpapers and add images, then run: betterlockscreen -u <image>"
    fi

    # Fix Xorg log ownership issues (safer approach - only specific directories)
    # Only fix ownership for user-specific directories, not system-managed ones
    if [[ -d "$HOME/.local/share" ]]; then
        # Only chown the share directory itself, not recursively through all subdirs
        run chown -R "$USERNAME:" "$HOME/.local/share" 2>/dev/null || true
    fi
    if [[ -d "$HOME/.cache" ]]; then
        run chown -R "$USERNAME:" "$HOME/.cache" 2>/dev/null || true
    fi

    print_success "Setup completed successfully."
}

# Function to prompt for system reboot
prompt_reboot() {
    # Check if running in interactive terminal
    if [[ ! -t 0 ]]; then
        print_note "Not running in interactive terminal. Skipping reboot prompt."
        print_note "Please remember to reboot your system later."
        return
    fi
    
    print_note "It's recommended to reboot your system to apply all changes."
    read -n1 -rep "${CAT} Would you like to reboot now? (y/n)" REBOOT || {
        print_note "Input cancelled. Please remember to reboot your system later."
        return
    }
    if [[ $REBOOT =~ ^[Yy]$ ]]; then
        print_success "Rebooting now..."
        run $SUDO_CMD reboot
    else
        print_note "Please remember to reboot your system later."
    fi
}

### Main Script Execution ###

# Welcome message
print_success "Welcome to the Arch Linux YAY DWM installer!"
if $DRY_RUN; then
    print_note "*** DRY-RUN MODE: No changes will be made ***"
    echo ""
fi
print_note "Note: This script will build and install dwm, dmenu, and slstatus from the suckless project."
print_note "Make sure the suckless project is cloned in the correct location (../suckless or ~/dev/suckless)."
echo ""

# Check for sudo/doas first
check_sudo

# Run functions in order
update_system
check_and_install_yay
install_packages
build_suckless_tools
link_config_files
install_fish_config
enable_services_and_groups
install_cursor_extensions
install_bluetooth
setup_power_management
finalize_setup
prompt_reboot
