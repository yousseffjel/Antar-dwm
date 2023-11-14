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
   app_pkgs="base-devel libx11 libxft libxinerama freetype2 xorg polkit-kde-agent ly kitty thunar feh picom unzip wget vim tmux lxappearance betterlockscreen"
   app_pkgs2="neofetch flameshot rofi dunst ffmpeg neovim viewnior mpv playerctl pamixer pavucontrol ffmpegthumbnailer tumbler thunar-archive-plugin htop xdg-user-dirs"
   app_pkgs3="timeshift grub-btrfs brave-bin bitwarden telegram-desktop opendoas rhythmbox qbittorrent trash-cli freedownloadmanager firefox-developer-edition"


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


#emote
#trash-cli-git
#steam
#gamemode
#gamescope
#mangohud
#spotify
#spicetify-cli
wl-clipboard
swaybg
swayidle
xorg-xwayland
xorg-xhost
xdg-desktop-portal-gtk
trash-cli
timeshift
grub-btrfs
brave-bin
bitwarden
telegram-desktop
opendoas
rhythmbox
qbittorrent
mpv
playerctl
ffmpeg
bat
ffmpegthumbnailer 
figlet
zsync
unzip
tar
sudo
sed
grep
wget
curl
nodejs
npm
cargo
tree
lazygit
binutils
coreutils
fuse
python-pip
xfce4-power-manager
trizen
tmux
freedownloadmanager
firefox-developer-edition
neovim
tumbler
ttf-font-awesome    
ttf-nerd-fonts-symbols-common
kotf-firamono-nerd
inter-font
otf-sora
ttf-fantasque-nerd
noto-fonts
noto-fonts-emoji
ttf-comfortaa
ttf-icomoon-feather
ttf-iosevka-nerd
gvfs
nordic-theme
papirus-icon-theme
starship


pipewire
pipewire-alsa
pipewire-audio
pipewire-jack
pipewire-pulse
gst-plugin-pipewire
wireplumber
networkmanager
network-manager-applet
bluez
bluez-utils
blueman
qt5-wayland
qt6-wayland
qt5-quickcontrols
qt5-quickcontrols2
qt5-graphicaleffects
hyprland-git
dunst
rofi-lbonn-wayland-git
waybar
swww
swaylock-effects-git
wlogout
grimblast-git
hyprpicker-git
slurp
swappy
cliphist
polkit-kde-agent
xdg-desktop-portal-hyprland
pacman-contrib
python-pyamdgpuinfo
parallel
jq
imagemagick
gparted
viewnior
qt5-imageformats
ffmpegthumbs
brightnessctl
pavucontrol
pamixer
nwg-look
kvantum
qt5ct
kitty
neofetch
dolphin
visual-studio-code-bin
vim
ark
zsh
eza
oh-my-zsh-git
zsh-theme-powerlevel10k-git



### link Config Files ###
printf " linking config files...\n"
sudo mkdir $HOME/.config
ln -sf $HOME/Antar-dwm/dotconfig/rofi $HOME/.config/
ln -sf $HOME/Antar-dwm/dotconfig/neofetch $HOME/.config/
ln -sf $HOME/Antar-dwm/dotconfig/sxhkd $HOME/.config/
ln -sf $HOME/Antar-dwm/dotconfig/kitty $HOME/.config/
ln -sf $HOME/Antar-dwm/dotconfig/betterlockscreen $HOME/.config/
ln -sf $HOME/Antar-dwm/dotconfig/dunst $HOME/.config/
ln -sf $HOME/Antar-dwm/dotconfig/tmux $HOME/.config/
ln -sf $HOME/Antar-dwm/dotconfig/Code $HOME/.config/
ln -sf $HOME/Antar-dwm/dotconfig/aliases $HOME/.config/





cp -r dotconfig/pipewire ~/.config/ 
    
### copy another files ###
# autostart for dwm
sudo mkdir -p $HOME/.local/share/dwm
sudo cp $HOME/Antar-dwm/dotconfig/autostart.sh $HOME/.local/share/dwm/

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
git clone https://github.com/yousseffjel/bin.git


### Enable ly  ###
printf " Enable ly"
sudo systemctl enable ly.service


# XSessions and dwm.desktop
if [[ ! -d /usr/share/xsessions ]]; then
    sudo mkdir /usr/share/xsessions
fi

cat > ./temp << "EOF"
[Desktop Entry]
Encoding=UTF-8
Name=dwm
Comment=Dynamic window manager
Exec=dwm
Icon=dwm
Type=XSession
EOF
sudo cp ./temp /usr/share/xsessions/dwm.desktop;rm ./temp



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
