#!/bin/bash

# Define variables
GREEN="$(tput setaf 2)[OK]$(tput sgr0)"
RED="$(tput setaf 1)[ERROR]$(tput sgr0)"
YELLOW="$(tput setaf 3)[NOTE]$(tput sgr0)"
CAT="$(tput setaf 6)[ACTION]$(tput sgr0)"
LOG="install.log"
CloneDir=$(pwd)

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

sleep 2


#pacman
if [ -f /etc/pacman.conf ] && [ ! -f /etc/pacman.conf.t2.bkp ]
    then
    echo -e "\033[0;32m[PACMAN]\033[0m adding extra spice to pacman..."

    sudo cp /etc/pacman.conf /etc/pacman.conf.t2.bkp
    sudo sed -i "/^#Color/c\Color\nILoveCandy
    /^#VerbosePkgLists/c\VerbosePkgLists
    /^#ParallelDownloads/c\ParallelDownloads = 5" /etc/pacman.conf
    sudo pacman -Syyu
    sudo pacman -Fy

else
    echo -e "\033[0;33m[SKIP]\033[0m pacman is already configured..."
fi

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
   base_pkgs="base-devel libx11 libxft libxinerama freetype2 xorg"
   app_pkgs="sxhkd polkit-kde-agent ly thunar xcolor feh picom unzip unrar wget vim tmux lxappearance betterlockscreen vscodium-bin network-manager-applet gvfs jq tlp tlpui auto-cpufreq"
   app_pkgs2="neofetch flameshot dunst ffmpeg xclip gparted mpv playerctl brightnessctl pamixer pavucontrol ffmpegthumbnailer tumbler thunar-archive-plugin htop xdg-user-dirs pacman-contrib"
   app_pkgs3="timeshift telegram-desktop figlet opendoas dust thorium-browser-bin trash-cli zsync tar xsel sed grep curl nodejs npm cargo tree lazygit binutils coreutils fuse python-pip xkblayout-state-git brightness"
   font_pkgs="ttf-joypixels ttf-font-awesome noto-fonts-emoji"


    if ! yay -S --noconfirm $base_pkgs $app_pkgs $app_pkgs2 $app_pkgs3 $font_pkgs 2>&1 | tee -a $LOG; then
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
if [[ ! -d $HOME/.config ]]; then
    mkdir -p $HOME/.config
fi

ln -sf $CloneDir/dotconfig/neofetch $HOME/.config/
ln -sf $CloneDir/dotconfig/sxhkd $HOME/.config/
ln -sf $CloneDir/dotconfig/betterlockscreen $HOME/.config/
ln -sf $CloneDir/dotconfig/dunst $HOME/.config/
ln -sf $CloneDir/dotconfig/kitty $HOME/.config/
ln -sf $CloneDir/dotconfig/picom $HOME/.config/
ln -sf $CloneDir/dotconfig/.Xresources $HOME/.Xresources
#cp -R  dotconfig/Code $HOME/.config/
sudo cp -R dotconfig/doas.conf /etc/doas.conf

# config for tmux
if [[ ! -d $HOME/.config/tmux ]]; then
    mkdir -p $HOME/.config/tmux
fi

ln -sf $CloneDir/dotconfig/tmux/tmux.conf $HOME/.config/tmux/tmux.conf
ln -sf $CloneDir/dotconfig/tmux/tmux.reset.conf $HOME/.config/tmux/tmux.reset.conf

sleep 1

if [[ ! -d $HOME/.tmux/plugins/tpm ]]; then
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
fi


# autostart for dwm
if [[ ! -d $HOME/.local/share/dwm ]]; then
    mkdir -p $HOME/.local/share/dwm
fi
ln -sf $CloneDir/dotconfig/autostart.sh $HOME/.local/share/dwm/autostart.sh


### Add Fonts ###
if [[ ! -d $HOME/.local/share/fonts ]]; then
    mkdir -p $HOME/.local/share/fonts
fi

if [[ ! -d /usr/share/fonts ]]; then
    sudo mkdir -p /usr/share/fonts
fi
cp -R Source/fonts/* $HOME/.local/share/fonts/
sudo cp -R Source/fonts/* /usr/share/fonts/

# Reloading Font
fc-cache -vf && sudo fc-cache -vf


### Add themes ###
if [[ ! -d $HOME/.themes ]]; then
    mkdir -p $HOME/.themes
fi

if [[ ! -d /usr/share/themes ]]; then
    sudo mkdir -p /usr/share/themes
fi
cp -R Source/themes/* $HOME/.themes/
sudo cp -R Source/themes/* /usr/share/themes/


### Add icons ###
if [[ ! -d $HOME/.icons ]]; then
    mkdir -p $HOME/.icons
fi

if [[ ! -d /usr/share/icons ]]; then
    sudo mkdir -p /usr/share/icons
fi
cp -R Source/icons/* $HOME/.icons/
sudo cp -R Source/icons/* /usr/share/icons/


### for vscode ###
#if [[ ! -d $HOME/.vscode ]]; then
#    mkdir -p $HOME/.vscode
#fi
#cp -R Source/code/* $HOME/.vscode


### check if src folder exists ###
if [[ ! -d $HOME/src ]]; then
    mkdir -p $HOME/src
fi

### Clone suckless's ###
if [[ ! -d $HOME/src/suckless ]]; then
     cd $HOME/src && git clone https://github.com/yousseffjel/suckless.git 
fi

cd ~/src/suckless/dwm;sudo rm -f config.h;make;sudo make install clean
cd ~/src/suckless/dmenu;sudo rm -f config.h;make;sudo make install clean
cd ~/src/suckless/slstatus;sudo rm -f config.h;make;sudo make install clean


### clone bin repo ###
if [[ ! -d $HOME/src/bin ]]; then
     cd $HOME/src && git clone https://github.com/yousseffjel/bin.git 
fi

# ------------------------------------------------------
# Install wallpapers
# ------------------------------------------------------
echo -e "${GREEN}"
figlet "Wallpapers"
echo -e "${NONE}"
if [ ! -d ~/src/wallpaper ]; then
    echo "Do you want to download the wallpapers from repository https://github.com/yousseffjel/wallpaper ?"
    echo ""
    if gum confirm "Do you want to download the repository?" ;then
        cd $HOME/src && git clone https://github.com/yousseffjel/wallpaper.git
        echo "Wallpapers from the repository installed successfully."
    fi
else
    echo ":: ~/src/wallpaper folder already exists."
fi
echo ""

### Enable ly  ###
printf " Enable ly"
sudo systemctl enable ly.service


# XSessions and dwm.desktop
if [[ ! -d /usr/share/xsessions ]]; then
    sudo mkdir -p /usr/share/xsessions
fi

sudo cp -R $CloneDir/dotconfig/dwm.desktop /usr/share/xsessions/dwm.desktop

### fix open kitty from thunar ###
if [[ ! -d $HOME/.config/xfce4 ]]; then
    mkdir -p $HOME/.config/xfce4
fi
ln -sf $CloneDir/dotconfig/helpers.rc ~/.config/xfce4/helpers.rc

# BLUETOOTH
read -n1 -rep "${CAT} OPTIONAL - Would you like to install Bluetooth packages? (y/n)" BLUETOOTH
if [[ $BLUETOOTH =~ ^[Yy]$ ]]; then
    printf " Installing Bluetooth Packages...\n"
 blue_pkgs="bluez bluez-utils blueman"
    if ! yay -S --noconfirm $blue_pkgs 2>&1 | tee -a $LOG; then
       	print_error "Failed to install bluetooth packages - please check the install.log"    
    printf " Activating Bluetooth Services...\n"
    sudo systemctl enable bluetooth.service
    sleep 2
    fi
else
    printf "${YELLOW} No bluetooth packages installed..\n"
	fi

#### Enable some servises ####
# apps for power manager 
sudo systemctl enable tlp.service
sleep 1
sudo systemctl start tlp.service
sleep 2

#sudo systemctl enable --now auto-cpufreq.service

# betterlockscreen
sudo systemctl enable --now betterlockscreen@$USER

# set wallpaper for betterlockscreen
betterlockscreen -u ~/src/wallpaper/cat_lofi_cafe.jpg --blur

# fix Xorg-log
sudo chown yusuf: ~/.local/share/*
sudo chown yusuf: ~/.local/*

### Script is done ###
printf "\n${GREEN} Installation Completed.\n"
printf "\e[1;32myou can now reboot.\e[0m\n"
