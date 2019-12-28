#!/bin/bash -e

# Amibian Launcher Install
# ------------------------
# Author: Henrik Noerfjand Stengaard
# Date: 2019-12-25
#
# A bash script to install HstWB Installer launcher for Amibian.


# show install dialog
dialog --clear --stdout \
--title "Install HstWB Installer" \
--yesno "Do you want to install HstWB Installer launcher?" 0 0

# exit, if no is selected
if [ $? -ne 0 ]; then
  exit
fi

# create backup of profile, if it doesn't exist
if [ -f ~/.profile -a ! -f ~/.profile_backup ]; then
	cp ~/.profile ~/.profile_backup
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
fi
chmod +x ~/.hstwb-installer/config.sh

# install hstwb bin
cp -f "$INSTALLROOT/hstwb.sh" "/usr/local/bin/hstwb"
chmod +x "/usr/local/bin/hstwb"

# copy hstwb installer profile
cp "$INSTALLROOT/install/boot/.profile" ~/.profile

# copy hstwb installer first boot
cp "$INSTALLROOT/install/first-boot.sh" ~/.hstwb-installer

# copy hstwb installer menu files
cp -r "$INSTALLROOT/install/menu_files" ~/.hstwb-installer

# add hstwb to amibian menu
if [ "$(grep -i "cat ~/.hstwb-installer/menu_files/hstwb" /usr/local/bin/menu)" == "" ]; then
	echo "cat ~/.hstwb-installer/menu_files/hstwb" >>/usr/local/bin/menu
fi
