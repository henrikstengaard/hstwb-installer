#!/bin/bash

# HstWB Installer Install
# -----------------------
# Author: Henrik Noerfjand Stengaard
# Date: 2020-04-02
#
# A bash script to install HstWB Installer launcher for Amibian.

# disable exit on eror and check if dialog is installed
#set +e
dpkg -s dialog >/dev/null 2>&1

# ask to install dialog, if dialog is not installed
if [ $? -ne 0 ]; then
	echo "Dialog is not installed and is required by HstWB Installer"
	echo ""
	while true; do
    		read -p "Do you want to install Dialog [Y/n]? " confirm
    		case $confirm in
			[Yy]* ) sudo apt-get install dialog; break;;
			[Nn]* ) exit;;
		esac
	done
fi

# fail, if dialog is not installed
dpkg -s dialog >/dev/null 2>&1
if [ $? -ne 0 ]; then
	echo "ERROR: Dialog is not installed"
	exit 1
fi

# detect amibian version
if [ -d ~/Amiga/conf/ ]; then
 	AMIBIAN_VERSION=1.5
	AMIGA_HDD_PATH=/home/amibian/Amiga/Hard-drives_HDF
	AMIGA_KICKSTARTS_PATH=/home/amibian/Amiga/kickstarts
	AMIBERRY_CONF_PATH=~/Amiga/conf
	UAE4ARM_CONF_PATH=
elif [ -d ~/amibian/amiberry/conf/ -o -d ~/amibian/chips_uae4arm/conf/ ]; then
	AMIBIAN_VERSION=1.4.1001
	AMIGA_HDD_PATH=/root/amibian/amiga_files/hdd
	AMIGA_KICKSTARTS_PATH=/root/amibian/amiga_files/kickstarts
	AMIBERRY_CONF_PATH=~/Amiga/conf
	UAE4ARM_CONF_PATH=~/amibian/chips_uae4arm/conf
else
	echo "ERROR: Unsupported Amibian version!"
	exit 1
fi

# show install dialog
dialog --clear --stdout \
--title "Detected Amibian v$AMIBIAN_VERSION" \
--yesno "Is it correct you're using Amibian v$AMIBIAN_VERSION?" 0 0

# exit, if detected amibian version is not correct
if [ $? -ne 0 ]; then
        echo "ERROR: Unsupported Amibian version!"
	exit 1
fi

# show install dialog
dialog --clear --stdout \
--title "Install HstWB Installer" \
--yesno "Do you want to install HstWB Installer?" 0 0

# exit, if no is selected
if [ $? -ne 0 ]; then
  exit
fi

CHANGE_AMIBIAN_BOOT=0

# show change amibian boot
dialog --clear --stdout \
--title "Change Amibian boot" \
--yesno "HstWB Installer can change Amibian boot to a configurable startup of either HstWB Installer, Amiga emulator with autostart or Amibian menu.\n\nThis will first make backups of '/etc/rc.local' and '~/.profile' files and patch these to use HstWB Installer.\n\nIf Amibian boot is changed to use HstWB Installer, Amibian boot can be changed from HstWB Installer menu, Setup, Amibian and Change boot.\n\nDo you want to change Amibian boot to use HstWB Installer?" 0 0

# exit, if no is selected
if [ $? -eq 0 ]; then
	CHANGE_AMIBIAN_BOOT=1
fi

# enable exit on error
set -e

# create hstwb installer profile, if it doesn't exist
if [ ! -d ~/.hstwb-installer ]; then
	mkdir ~/.hstwb-installer
fi

# get root directories
INSTALL_ROOT="$(dirname "$(readlink -fm "$0")")"
HSTWB_INSTALLER_ROOT="$(dirname "$(dirname "$INSTALL_ROOT")")"

# update or create hstwb installer config.sh
if [ -f ~/.hstwb-installer/config.sh ]; then
	sed -e "s/^\(export HSTWB_INSTALLER_ROOT=\).*/\1\"$(echo "$HSTWB_INSTALLER_ROOT" | sed -e "s/\//\\\\\//g")\"/g" ~/.hstwb-installer/config.sh >~/.hstwb-installer/_config.sh
	mv -f ~/.hstwb-installer/_config.sh ~/.hstwb-installer/config.sh
else
	echo "#!/bin/bash -e" >~/.hstwb-installer/config.sh
	echo "export HSTWB_INSTALLER_ROOT=\"$HSTWB_INSTALLER_ROOT\"" >>~/.hstwb-installer/config.sh
	echo "export HSTWB_INSTALLER_BOOT=\"emulator\"" >>~/.hstwb-installer/config.sh
	echo "export AMIGA_HDD_PATH=\"$AMIGA_HDD_PATH\"" >>~/.hstwb-installer/config.sh
	echo "export AMIGA_KICKSTARTS_PATH=\"$AMIGA_KICKSTARTS_PATH\"" >>~/.hstwb-installer/config.sh
	echo "export AMIBIAN_VERSION=\"$AMIBIAN_VERSION\"" >>~/.hstwb-installer/config.sh
	echo "export AMIBERRY_CONF_PATH=\"$AMIBERRY_CONF_PATH\"" >>~/.hstwb-installer/config.sh
	echo "export UAE4ARM_CONF_PATH=\"$UAE4ARM_CONF_PATH\"" >>~/.hstwb-installer/config.sh
fi
chmod +x ~/.hstwb-installer/config.sh

# run hstwb installer config
. ~/.hstwb-installer/config.sh

# install hstwb bin
cp -f "$INSTALL_ROOT/hstwb.sh" "/usr/local/bin/hstwb"
chmod +x "/usr/local/bin/hstwb"

# change .profile, if change amibian boot
if [ $CHANGE_AMIBIAN_BOOT -eq 1 ]; then
	# create backup of profile, if it doesn't exist
	if [ -f ~/.profile -a ! -f ~/.profile_backup ]; then
		cp ~/.profile ~/.profile_backup
	fi

	# copy hstwb installer profile
	cp "$INSTALL_ROOT/install/boot/.profile.$AMIBIAN_VERSION" ~/.profile
fi

# copy hstwb installer menu files
cp -r "$INSTALL_ROOT/install/menu_files" ~/.hstwb-installer

# install for amibian version
case $AMIBIAN_VERSION in
	1.5)
		# change rc.local, if change amibian boot
		if [ $CHANGE_AMIBIAN_BOOT -eq 1 ]; then
			# create backup of rc.local, if it doesn't exist
			if [ -f /etc/rc.local -a ! -f /etc/rc.local_backup ]; then
				sudo cp /etc/rc.local /etc/rc.local_backup
			fi

			# disable start on boot
			if [ "$(grep -i "exec \/home\/amibian\/.amibian_scripts\/start-on-boot.sh" /etc/rc.local)" != "" ]; then
				sudo sed -e "s/^\(exec \/home\/amibian\/.amibian_scripts\/start-on-boot.sh\).*/#\1/g" /etc/rc.local >/tmp/_rc.local
				sudo mv -f /tmp/_rc.local /etc/rc.local
			fi
		fi

		# create backup of usbmount.conf, if it doesn't exist
		if [ -f /etc/usbmount/usbmount.conf -a ! -f /etc/usbmount/usbmount.conf_backup ]; then
			sudo cp /etc/usbmount/usbmount.conf /etc/usbmount/usbmount.conf_backup
		fi

		# change usbmount.conf mountoptions, if not already changed. this is to ensure fat32 usb devices are automounted as r/w
		if [ "$(grep -i "^MOUNTOPTIONS=" /etc/usbmount/usbmount.conf)" != "MOUNTOPTIONS=\"sync,noexec,nodev,noatime,nodiratime,nosuid,users,rw\"" ]; then
			sudo sed -e "s/^MOUNTOPTIONS=.*/MOUNTOPTIONS=\"sync,noexec,nodev,noatime,nodiratime,nosuid,users,rw\"/g" /etc/usbmount/usbmount.conf >/tmp/_usbmount.conf
			sudo mv -f /tmp/_usbmount.conf /etc/usbmount/usbmount.conf
		fi

		# change usbmount.conf fs_mountoptions, if not already changed. this is to ensure fat32 usb devices are automounted as r/w
		if [ "$(grep -i "^FS_MOUNTOPTIONS=" /etc/usbmount/usbmount.conf)" != "FS_MOUNTOPTIONS=\"-fstype=vfat,umask=000\"" ]; then
			sudo sed -e "s/^FS_MOUNTOPTIONS=.*/FS_MOUNTOPTIONS=\"-fstype=vfat,umask=000\"/g" /etc/usbmount/usbmount.conf >/tmp/_usbmount.conf
			sudo mv -f /tmp/_usbmount.conf /etc/usbmount/usbmount.conf
		fi

		# add hstwb to amibian menu
		if [ "$(grep -i "hstwb" ~/.amibian_scripts/cli_menu/menu.txt)" == "" ]; then
			cat ~/.hstwb-installer/menu_files/hstwb >>~/.amibian_scripts/cli_menu/menu.txt
		fi
		;;
	1.4.1001)
		# add hstwb to amibian menu
		if [ "$(grep -i "cat ~/.hstwb-installer/menu_files/hstwb" /usr/local/bin/menu)" == "" ]; then
			echo "cat ~/.hstwb-installer/menu_files/hstwb" >>/usr/local/bin/menu
		fi
		;;
esac

# amiberry conf
if [ ! "$AMIBERRY_CONF_PATH" == "" -a -d "$AMIBERRY_CONF_PATH" ]; then
	# copy amiberry configs
	cp -R "$HSTWB_INSTALLER_ROOT/emulators/amiberry/configs/." "$AMIBERRY_CONF_PATH"

	# replace amiga hdd path placeholders with path
	find "$AMIBERRY_CONF_PATH" -name "hstwb-*.uae" -type f -exec sed -i "s/\\$\\[AMIGA_HDD_PATH\\]/$(echo "$AMIGA_HDD_PATH" | sed -e "s/\//\\\\\//g")/g" {} \;
	find "$AMIBERRY_CONF_PATH" -name "hstwb-*.uae" -type f -exec sed -i "s/\\$\\[AMIGA_KICKSTARTS_PATH\\]/$(echo "$AMIGA_KICKSTARTS_PATH" | sed -e "s/\//\\\\\//g")/g" {} \;
fi

# uae4arm conf
if [ ! "$UAE4ARM_CONF_PATH" == "" -a -d "$UAE4ARM_CONF_PATH" ]; then
	# copy chips uae4arm configs
	cp -R "$HSTWB_INSTALLER_ROOT/emulators/chips_uae4arm/configs/." "$UAE4ARM_CONF_PATH"

	# replace amiga hdd path placeholders with path
	find "$UAE4ARM_CONF_PATH" -name "hstwb-*.uae" -type f -exec sed -i "s/\\$\\[AMIGA_HDD_PATH\\]/$(echo "$AMIGA_HDD_PATH" | sed -e "s/\//\\\\\//g")/g" {} \;
	find "$UAE4ARM_CONF_PATH" -name "hstwb-*.uae" -type f -exec sed -i "s/\\$\\[AMIGA_KICKSTARTS_PATH\\]/$(echo "$AMIGA_KICKSTARTS_PATH" | sed -e "s/\//\\\\\//g")/g" {} \;
fi

# disable exit on eror
set +e

# show install dialog
dialog --clear --stdout \
--title "Success" \
--yesno "Successfully installed HstWB Installer.\n\nType hstwb and press enter from shell at anytime to start HstWB Installer menu.\n\nDo you want to reboot and go through first time use steps now?" 0 0

# reboot to first time use, if yes is selected
if [ $? -eq 0 ]; then
	# create first time use trigger
	touch ~/.hstwb-installer/.first-time-use

 	reboot
fi
