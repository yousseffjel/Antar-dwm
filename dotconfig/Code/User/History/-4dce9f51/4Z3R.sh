#!/bin/bash

# Define variables
GREEN="$(tput setaf 2)[OK]$(tput sgr0)"
RED="$(tput setaf 1)[ERROR]$(tput sgr0)"
YELLOW="$(tput setaf 3)[NOTE]$(tput sgr0)"
CAT="$(tput setaf 6)[ACTION]$(tput sgr0)"
LOG="install.log"

# Set the script to exit on error
set -e

printf "$(tput setaf 2) Welcome to the Arch Linux YAY dwm installer!\n $(tput sgr0)"

sleep 2

printf "$YELLOW PLEASE BACKUP YOUR FILES BEFORE PROCEEDING!
This script will overwrite some of your configs and files!"

sleep 2

printf "\n
$YELLOW  Some commands requires you to enter your password inorder to execute
If you are worried about entering your password, you can cancel the script now with CTRL Q or CTRL C and review contents of this script. \n"

sleep 3

# Check if yay is installed
ISyay=/sbin/yay

if [ -f "$ISyay" ]; then
    printf "\n%s - yay was located, moving on.\n" "$GREEN"
else 
    printf "\n%s - yay was NOT located\n" "$YELLOW"
    read -n1 -rep "${CAT} Would you like to install yay (y,n)" INST
    if [[ $INST =~ ^[Yy]$ ]]; then
        git clone https://aur.archlinux.org/yay.git
        cd yay
        makepkg -si --noconfirm 2>&1 | tee -a $LOG
        cd ..
    else
        printf "%s - yay is required for this script, now exiting\n" "$RED"
        exit
    fi
# update system before proceed
    printf "${YELLOW} System Update to avoid issue\n" 
    yay -Syu --noconfirm 2>&1 | tee -a $LOG
fi

# Function to print error messages
print_error() {
    printf " %s%s\n" "$RED" "$1" "$NC" >&2
}

# Function to print success messages
print_success() {
    printf "%s%s%s\n" "$GREEN" "$1" "$NC"
}


### Install packages ####
read -n1 -rep "${CAT} Would you like to install the packages? (y/n)" inst
echo

if [[ $inst =~ ^[Nn]$ ]]; then
    printf "${YELLOW} No packages installed. Goodbye! \n"
            exit 1
        fi

if [[ $inst =~ ^[Yy]$ ]]; then
   app_pkgs="base-devel libx11 libxft libxinerama freetype2 syncthing deemix-git sxhkd local-by-flywheel xorg polkit-kde-agent ly kitty thunar feh picom unzip wget vim tmux lxappearance betterlockscreen visual-studio-code-bin network-manager-applet gvfs jq tlp auto-cpufreq"
   app_pkgs2="neofetch flameshot rofi dunst ffmpeg xclip bat neovim viewnior gparted mpv playerctl brightnessctl pamixer pavucontrol ffmpegthumbnailer tumbler thunar-archive-plugin htop xdg-user-dirs pacman-contrib ttf-joypixels ttf-font-awesome noto-fonts-emoji"
   app_pkgs3="timeshift grub-btrfs brave-bin telegram-desktop figlet opendoas rhythmbox qbittorrent trash-cli freedownloadmanager firefox-developer-edition zsync tar sudo sed grep curl nodejs npm cargo tree lazygit binutils coreutils fuse python-pip"


    if ! yay -S --noconfirm $app_pkgs $app_pkgs2 $app_pkgs3 2>&1 | tee -a $LOG; then
        print_error " Failed to install additional packages - please check the install.log \n"
        exit 1
    fi
    xdg-user-dirs-update
    echo
    print_success " All necessary packages installed successfully."

else
    echo
    print_error " Packages not installed - please check the install.log"
    sleep 1
fi


### link Config Files ###
printf " linking config files...\n"
#sudo mkdir $HOME/.config
if [[ ! -d $HOME/.config ]]; then
    sudo mkdir -p $HOME/.config
fi

ln -sf $HOME/Antar-dwm/dotconfig/rofi $HOME/.config/
ln -sf $HOME/Antar-dwm/dotconfig/neofetch $HOME/.config/
ln -sf $HOME/Antar-dwm/dotconfig/sxhkd $HOME/.config/
ln -sf $HOME/Antar-dwm/dotconfig/kitty $HOME/.config/
ln -sf $HOME/Antar-dwm/dotconfig/betterlockscreen $HOME/.config/
ln -sf $HOME/Antar-dwm/dotconfig/dunst $HOME/.config/
ln -sf $HOME/Antar-dwm/dotconfig/tmux $HOME/.config/
ln -sf $HOME/Antar-dwm/dotconfig/Code $HOME/.config/
ln -sf $HOME/Antar-dwm/dotconfig/aliases $HOME/.config/
ln -sf $HOME/Antar-dwm/dotconfig/picom $HOME/.config/
ln -sf $HOME/Antar-dwm/dotconfig/.Xresources $HOME/

# autostart for dwm
sudo mkdir -p $HOME/.local/share/dwm
sudo ln -sf $HOME/Antar-dwm/dotconfig/autostart.sh $HOME/.local/share/dwm/


### copy another files ###
# config doas
sudo cp $HOME/Antar-dwm/dotconfig/doas.conf /etc/

### for tmux ###
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm


### Add Fonts ###
sudo mkdir -p $HOME/.local/share/fonts
sudo mkdir -p /usr/share/fonts
sudo cp -r $HOME/Antar-dwm/Source/fonts/* $HOME/.local/share/fonts/
sudo cp -r $HOME/Antar-dwm/Source/fonts/* /usr/share/fonts/

# Reloading Font
fc-cache -vf


### Add themes ###
sudo mkdir -p $HOME/.themes
sudo mkdir -p /usr/share/themes
sudo cp -r $HOME/Antar-dwm/Source/themes/* $HOME/.themes/
sudo cp -r $HOME/Antar-dwm/Source/themes/* /usr/share/themes/


### Add icons ###
sudo mkdir -p $HOME/.icons
sudo mkdir -p /usr/share/icons
sudo cp -r $HOME/Antar-dwm/Source/icons/* $HOME/.icons/
sudo cp -r $HOME/Antar-dwm/Source/icons/* /usr/share/icons/


### for vscode ###
sudo mkdir -p $HOME/.vscode
sudo cp -r $HOME/Antar-dwm/Source/code/* $HOME/.vscode


### Clone suckless's ###
cd $HOME/
git clone https://github.com/yousseffjel/suckless.git
cd ~/suckless/dwm;sudo rm -f config.h;make;sudo make install clean
cd ~/suckless/slstatus;sudo rm -f config.h;make;sudo make install clean


### clone bin repo
cd $HOME/
git clone https://github.com/yousseffjel/bin.git


### Enable ly  ###
printf " Enable ly"
sudo systemctl enable ly.service


# XSessions and dwm.desktop
if [[ ! -d /usr/share/xsessions ]]; then
    sudo mkdir -p /usr/share/xsessions
fi

sudo cp $HOME/Antar-dwm/dotconfig/dwm.desktop /usr/share/xsessions/dwm.desktop


# BLUETOOTH
read -n1 -rep "${CAT} OPTIONAL - Would you like to install Bluetooth packages? (y/n)" BLUETOOTH
if [[ $BLUETOOTH =~ ^[Yy]$ ]]; then
    printf " Installing Bluetooth Packages...\n"
 blue_pkgs="bluez bluez-utils blueman"
    if ! yay -S --noconfirm $blue_pkgs 2>&1 | tee -a $LOG; then
       	print_error "Failed to install bluetooth packages - please check the install.log"    
    printf " Activating Bluetooth Services...\n"
    sudo systemctl enable --now bluetooth.service
    sleep 2
    fi
else
    printf "${YELLOW} No bluetooth packages installed..\n"
	fi

#### Enable some servises ####
 
# apps for power manager 
sudo systemctl enable --now tlp.service
sudo systemctl enable --now auto-cpufreq.service

# betterlockscreen
sudo systemctl enable betterlockscreen@$USER

# set wallpaper for betterlockscreen
betterlockscreen -u ~/Antar-dwm/wallpapers/cat_lofi_cafe.jpg --blur

# fix Xorg-log
sudo chown yusuf: ~/.local/share/*
sudo chown yusuf: ~/.local/*

# pacman
if [ -f /etc/pacman.conf ] && [ ! -f /etc/pacman.conf.t2.bkp ]
    then

    echo "adding extra spice to pacman..."
    sudo cp /etc/pacman.conf /etc/pacman.conf.t2.bkp
    sudo sed -i "/^#Color/c\Color\nILoveCandy
    /^#VerbosePkgLists/c\VerbosePkgLists
    /^#ParallelDownloads/c\ParallelDownloads = 5" /etc/pacman.conf
fi

sleep 3

    
### Script is done ###
printf "\n${GREEN} Installation Completed.\n"
printf "\e[1;32myou can now reboot.\e[0m\n"
