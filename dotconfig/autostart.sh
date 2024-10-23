dbus-update-activation-environment --systemd DBUS_SESSION_BUS_ADDRESS DISPLAY XAUTHORITY &
/usr/lib/polkit-kde-authentication-agent-1 &
xrdb -merge ~/.Xresources &
slstatus &
picom &
$HOME/src/bin/wallpaper.sh &
sxhkd -c $HOME/.config/sxhkd/sxhkdrc & 
blueman-applet &
nm-applet --indicator &
copyq &
dunst &
flameshot
