#!/bin/bash

# Define constants for colors and log file
GREEN="$(tput setaf 2)[OK]$(tput sgr0)"
RED="$(tput setaf 1)[ERROR]$(tput sgr0)"
YELLOW="$(tput setaf 3)[NOTE]$(tput sgr0)"
CAT="$(tput setaf 6)[ACTION]$(tput sgr0)"
LOG="install.log"
CloneDir=$(pwd)

# Set the script to exit on error and log failures
set -e 
trap 'echo -e "${RED}Script failed. Check $LOG for more details.${NONE}"' ERR

# Utility functions for printing messages
print_error() {
    printf " %s%s\n" "$RED" "$1" "$NC" >&2
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

# Function to update the system and install Reflector for faster mirrors
update_system() {
    print_note "Updating the system and optimizing mirrors..."
    sudo pacman -S --noconfirm reflector
    sudo reflector --verbose --latest 10 --sort rate --save /etc/pacman.d/mirrorlist
    sudo pacman -Syyu --noconfirm
    sudo pacman -Fy
}

# Function to check if yay is installed, and install it if not
check_and_install_yay() {
    if command -v yay &> /dev/null; then
        print_success "yay is already installed."
    else 
        print_note "yay not found. Installing yay..."
        sudo pacman -S --noconfirm git base-devel
        git clone https://aur.archlinux.org/yay.git
        cd yay
        makepkg -si --noconfirm 2>&1 | tee -a $LOG
        cd ..
        print_success "yay installed successfully."
    fi
}

# Function to install a list of packages using yay
install_packages() {
    base_pkgs="base-devel libx11 libxft libxinerama freetype2 xorg"
    app_pkgs="sxhkd polkit-kde-agent ly thunar xcolor feh picom unzip unrar wget vim tmux lxappearance betterlockscreen vscodium-bin network-manager-applet gvfs jq tlp tlpui auto-cpufreq"
    app_pkgs2="neofetch flameshot dunst ffmpeg xclip gparted mpv playerctl brightnessctl pamixer pavucontrol ffmpegthumbnailer tumbler thunar-archive-plugin htop xdg-user-dirs pacman-contrib"
    app_pkgs3="timeshift telegram-desktop figlet opendoas dust thorium-browser-bin trash-cli zsync tar xsel sed grep curl nodejs npm cargo tree lazygit binutils coreutils fuse python-pip xkblayout-state-git brightness"
    font_pkgs="ttf-joypixels ttf-font-awesome noto-fonts-emoji"

    print_action "Installing packages..."
    if ! yay -S --noconfirm $base_pkgs $app_pkgs $app_pkgs2 $app_pkgs3 $font_pkgs 2>&1 | tee -a $LOG; then
        print_error "Failed to install additional packages. Please check the install.log."
        exit 1
    fi
    xdg-user-dirs-update
    print_success "All packages installed successfully."
}

# Function to link config files
link_config_files() {
    print_action "Linking configuration files..."

    # Ensure .config directory exists
    mkdir -p $HOME/.config

    # Link various config files
    ln -sf $CloneDir/dotconfig/neofetch $HOME/.config/
    ln -sf $CloneDir/dotconfig/sxhkd $HOME/.config/
    ln -sf $CloneDir/dotconfig/betterlockscreen $HOME/.config/
    ln -sf $CloneDir/dotconfig/dunst $HOME/.config/
    ln -sf $CloneDir/dotconfig/kitty $HOME/.config/
    ln -sf $CloneDir/dotconfig/picom $HOME/.config/
    ln -sf $CloneDir/dotconfig/.Xresources $HOME/.Xresources
    sudo cp -R $CloneDir/dotconfig/doas.conf /etc/doas.conf

    # Configure tmux
    mkdir -p $HOME/.config/tmux
    ln -sf $CloneDir/dotconfig/tmux/tmux.conf $HOME/.config/tmux/tmux.conf
    ln -sf $CloneDir/dotconfig/tmux/tmux.reset.conf $HOME/.config/tmux/tmux.reset.conf

    # Ensure tmux plugin manager is installed
    if [[ ! -d $HOME/.tmux/plugins/tpm ]]; then
        git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
    fi

    print_success "Configuration files linked successfully."
}

# Function to set up fonts, themes, and icons
setup_fonts_themes_icons() {
    print_action "Setting up fonts, themes, and icons..."

    # Ensure necessary directories exist
    mkdir -p $HOME/.local/share/fonts
    mkdir -p /usr/share/fonts
    sudo mkdir -p /usr/share/themes
    sudo mkdir -p /usr/share/icons

    # Copy fonts, themes, and icons
    cp -R Source/fonts/* $HOME/.local/share/fonts/
    sudo cp -R Source/fonts/* /usr/share/fonts/
    sudo cp -R Source/themes/* /usr/share/themes/
    sudo cp -R Source/icons/* /usr/share/icons/

    # Reload fonts
    fc-cache -vf && sudo fc-cache -vf

    print_success "Fonts, themes, and icons set up successfully."
}

# Function to optionally install Bluetooth packages
install_bluetooth() {
    read -n1 -rep "${CAT} OPTIONAL - Would you like to install Bluetooth packages? (y/n)" BLUETOOTH
    if [[ $BLUETOOTH =~ ^[Yy]$ ]]; then
        print_action "Installing Bluetooth Packages..."
        blue_pkgs="bluez bluez-utils blueman"
        if ! yay -S --noconfirm $blue_pkgs 2>&1 | tee -a $LOG; then
            print_error "Failed to install Bluetooth packages. Please check the install.log."
        else
            sudo systemctl enable bluetooth.service
            sudo systemctl start bluetooth.service
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

# Function to set up power management
setup_power_management() {
    sudo systemctl enable tlp.service
    sudo systemctl start tlp.service

    # Optionally install Auto-CPUFreq
    read -n1 -rep "${CAT} OPTIONAL - Would you like to install Auto-CPUFreq? (y/n)" CPUFREQ
    if [[ $CPUFREQ =~ ^[Yy]$ ]]; then
        print_action "Installing Auto-CPUFreq..."
        yay -S --noconfirm auto-cpufreq 2>&1 | tee -a $LOG
        sudo systemctl enable --now auto-cpufreq.service
        print_success "Auto-CPUFreq installed and enabled."
    else
        print_note "Auto-CPUFreq installation skipped."
    fi
}

# Function to finalize the setup
finalize_setup() {
    sudo systemctl enable --now betterlockscreen@$USER
    betterlockscreen -u ~/src/wallpaper/cat_lofi_cafe.jpg --blur

    # Fix Xorg log ownership issues
    sudo chown $USER: ~/.local/share/*
    sudo chown $USER: ~/.local/*

    print_success "Setup completed successfully."
}

# Function to prompt for system reboot
prompt_reboot() {
    print_note "It's recommended to reboot your system to apply all changes."
    read -n1 -rep "${CAT} Would you like to reboot now? (y/n)" REBOOT
    if [[ $REBOOT =~ ^[Yy]$ ]]; then
        print_success "Rebooting now..."
        sudo reboot
    else
        print_note "Please remember to reboot your system later."
    fi
}

### Main Script Execution ###

# Welcome message
print_success "Welcome to the Arch Linux YAY DWM installer!"

# Run functions in order
update_system
check_and_install_yay
install_packages
link_config_files
setup_fonts_themes_icons
install_bluetooth
setup_power_management
finalize_setup
prompt_reboot
