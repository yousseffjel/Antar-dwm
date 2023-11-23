dbus-update-activation-environment --systemd DBUS_SESSION_BUS_ADDRESS DISPLAY XAUTHORITY &
xrdb -merge ~/.Xresources &
/usr/lib/polkit-kde-authentication-agent-1 &
slstatus &
$HOME/bin/wallpaper.sh &
picom &
sxhkd -c $HOME/.config/sxhkd/sxhkdrc & 
blueman-applet &
nm-applet --indicator &
copyq &
syncthing &
dunst &
flameshot
