# ===================================
#	     Install GUI
#
# - installs drivers, xorg,
#   a desktop enviornment, display
#   manager and some extras
#
# ===================================

if [[ $(id -u) -ne 0 ]]; then
	printf "\nRun as root.\n"
	exit 1
fi

echo

read -p "Press [ENTER] to install GUI..."

# update system
sudo pacman -Syyu

# FOR VBOX (graphics driver)
sudo pacman -S --noconfirm virtualbox-guest-utils

# installing xorg (display server)
sudo pacman -S --noconfirm xorg xterm xorg-xinit

# install gnome desktop enviorment
sudo pacman -S --noconfirm gnome gnome-extra

# install sound system
sudo pacman -S --noconfirm pulseaudio pavucontrol

# install, enable, and start Gnome display Manager
sudo pacman -S --noconfirm gdm
sudo systemctl enable gdm
sudo systemctl start gdm

