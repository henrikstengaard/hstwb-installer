#!/bin/bash -e

# HstWB Installer Install
# -----------------------
# Author: Henrik Noerfjand Stengaard
# Date: 2020-01-18
#
# Bash script to install HstWB Installer launcher for DietPi.


# show install dialog
dialog --clear --stdout \
--title "Install HstWB Installer" \
--yesno "Do you want to install HstWB Installer launcher?" 0 0

# exit, if no is selected
if [ $? -ne 0 ]; then
  exit
fi

# create backup of custom autostart
if sudo test -f /var/lib/dietpi/dietpi-autostart/custom.sh.bak; then
	sudo touch /var/lib/dietpi/dietpi-autostart/custom.sh
else
	sudo cp /var/lib/dietpi/dietpi-autostart/custom.sh /var/lib/dietpi/dietpi-autostart/custom.sh.bak
fi

# create hstwb installer profile, if it doesn't exist
if [ ! -d ~/.hstwb-installer ]; then
	mkdir ~/.hstwb-installer
fi

# get root directories
INSTALLROOT="$(dirname "$(readlink -fm "$0")")"
HSTWBINSTALLERROOT="$(dirname "$(dirname "$INSTALLROOT")")"

# update or create hstwb installer config.sh
if [ -f ~/.hstwb-installer/config.sh ]; then
	sed -e "s/^\(export HSTWBINSTALLERROOT=\).*/\1\"$(echo "$HSTWBINSTALLERROOT" | sed -e "s/\//\\\\\//g")\"/g" ~/.hstwb-installer/config.sh >~/.hstwb-installer/_config.sh
	mv -f ~/.hstwb-installer/_config.sh ~/.hstwb-installer/config.sh
else
	echo "#!/bin/bash -e" >~/.hstwb-installer/config.sh
	echo "export HSTWBINSTALLERROOT=\"$HSTWBINSTALLERROOT\"" >>~/.hstwb-installer/config.sh
	echo "export HSTWBINSTALLERBOOT=\"emulator\"" >>~/.hstwb-installer/config.sh
	echo "export AMIGAHDDS=\"/mnt/dietpi_userdata/amiberry/hdds\"" >>~/.hstwb-installer/config.sh
	echo "export AMIGAKICKSTARTS=\"/mnt/dietpi_userdata/amiberry/kickstarts\"" >>~/.hstwb-installer/config.sh
fi
chmod +x ~/.hstwb-installer/config.sh

# create first time use trigger
#touch ~/.hstwb-installer/.first-time-use

# install hstwb bin
sudo cp -f "$INSTALLROOT/hstwb.sh" "/usr/local/bin/hstwb"
sudo chmod +x "/usr/local/bin/hstwb"

# copy hstwb installer custom autostart
#cp "$INSTALLROOT/install/boot/.profile" ~/.profile
sudo cp "$INSTALLROOT/install/autostart/custom.sh" "/var/lib/dietpi/dietpi-autostart/custom.sh"


# copy hstwb installer menu files
#cp -r "$INSTALLROOT/install/menu_files" ~/.hstwb-installer

# add hstwb to amibian menu
#if [ "$(grep -i "cat ~/.hstwb-installer/menu_files/hstwb" /usr/local/bin/menu)" == "" ]; then
#	echo "cat ~/.hstwb-installer/menu_files/hstwb" >>/usr/local/bin/menu
#fi

# copy amiberry configs
#cp -R "$HSTWBINSTALLERROOT/emulators/amiberry/configs/." ~/amibian/amiberry/conf/

# copy chips uae4arm configs
#cp -R "$HSTWBINSTALLERROOT/emulators/chips_uae4arm/configs/." ~/amibian/chips_uae4arm/conf/

# show install dialog
dialog --clear --stdout \
--title "Success" \
--yesno "Successfully installed HstWB Installer. For first time use Amibian should be rebooted. Do you want to reboot now?" 0 0

# reboot, if yes is selected
if [ $? -eq 0 ]; then
 	sudo reboot
fi
