#!/bin/bash

# HstWB Installer Install
# -----------------------
# Author: Henrik Noerfjand Stengaard
# Date: 2020-12-25
#
# A bash script to install HstWB Installer launcher for Raspberry Pi.

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

# raspberry pi os configuration
AMIGA_HDD_PATH=~/amiga/hdfs
AMIGA_KICKSTARTS_PATH=~/amiga/kickstarts
AMIBERRY_EMULATOR_PATH=~/amiga/emulators/amiberry
AMIBERRY_CONF_PATH=~/amiga/emulators/amiberry/conf/

# show install dialog
dialog --clear --stdout \
--title "Install HstWB Installer" \
--yesno "Do you want to install HstWB Installer?" 0 0

# exit, if no is selected
if [ $? -ne 0 ]; then
  exit
fi

CHANGE_BOOT=0

# show change raspberry pi os boot
dialog --clear --stdout \
--title "Change Raspberry Pi OS boot" \
--yesno "HstWB Installer can change Raspberry Pi OS boot to a configurable startup of either HstWB Installer, Amiga emulator with autostart or console.\n\nThis will first make a backup of '~/.profile' and patch it to use HstWB Installer.\n\nIf Raspberry Pi OS boot is changed to use HstWB Installer, Raspberry Pi OS boot can be changed from HstWB Installer menu, Setup, Raspberry Pi OS and Change boot.\n\nDo you want to change Raspberry Pi OS boot to use HstWB Installer?" 0 0

# set change boot true, if yes is selected
if [ $? -eq 0 ]; then
	CHANGE_BOOT=1
fi

# enable exit on error
#set -e

# create hstwb installer home directory, if it doesn't exist
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
        echo "export AMIBERRY_EMULATOR_PATH=\"$AMIBERRY_EMULATOR_PATH\"" >>~/.hstwb-installer/config.sh
	echo "export AMIBERRY_CONF_PATH=\"$AMIBERRY_CONF_PATH\"" >>~/.hstwb-installer/config.sh
fi
chmod +x ~/.hstwb-installer/config.sh

# run hstwb installer config
. ~/.hstwb-installer/config.sh

# install hstwb bin
sudo cp -f "$INSTALL_ROOT/hstwb.sh" "/usr/local/bin/hstwb"
sudo chmod +x "/usr/local/bin/hstwb"

# change .profile, if change boot
if [ $CHANGE_BOOT -eq 1 ]; then
	# create backup of profile, if it doesn't exist
	if [ -f ~/.profile -a ! -f ~/.profile_backup ]; then
		cp ~/.profile ~/.profile_backup
	fi

	# patch .profile to start ~/.hstwb-installer/profile.sh
	if [ "$(grep -i "\$HOME/.hstwb-installer/profile.sh" ~/.profile)" == "" ]; then
		echo "" >>~/.profile
		echo "# run hstwb installer profile" >>~/.profile
		echo "if [ -f \"\$HOME/.hstwb-installer/profile.sh\" ]; then" >>~/.profile
		echo "  . \"\$HOME/.hstwb-installer/profile.sh\"" >>~/.profile
		echo "fi" >>~/.profile
	fi

	# copy hstwb installer profile
	cp "$INSTALL_ROOT/install/profile.sh" ~/.hstwb-installer/profile.sh
fi


# show autologin dialog
dialog --clear --stdout \
--title "Enable autologin" \
--yesno "This will automatically login as user '$USER' at boot and allow automatically start of Amiga emulator or HstWB Installer at boot.\n\nDo you want to enable autologin?" 0 0

AUTOLOGIN=0

# set autologin true, if yes is selected
if [ $? -eq 0 ]; then
        AUTOLOGIN=1
fi

# enable autologin
if [ $AUTOLOGIN -eq 1 ]; then
	sudo systemctl set-default multi-user.target
	sudo ln -fs /lib/systemd/system/getty@.service /etc/systemd/system/getty.target.wants/getty@tty1.service
        sudo cat > /tmp/_autologin.conf << EOF
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin $USER --noclear %I \$TERM
EOF
	sudo mv -f /tmp/_autologin.conf /etc/systemd/system/getty@tty1.service.d/autologin.conf
else
	sudo systemctl set-default multi-user.target
	sudo ln -fs /lib/systemd/system/getty@.service /etc/systemd/system/getty.target.wants/getty@tty1.service
	sudo rm /etc/systemd/system/getty@tty1.service.d/autologin.conf
fi


# show network at boot dialog
dialog --clear --stdout \
--title "Delay network at boot" \
--yesno "This will delay network at boot and make Amiga emulator, HstWB Installer or console boot faster.\n\nDo you want boot to wait until a network connection is established?" 0 0

DELAYNETWORK=0

# set delay network true, if yes is selected
if [ $? -eq 0 ]; then
	DELAYNETWORK=1
fi

# enable delay network
if [ $DELAYNETWORK -eq 1 ]; then
	if [ -f /etc/systemd/system/dhcpcd.service.d/wait.conf ]; then
		sudo rm -f /etc/systemd/system/dhcpcd.service.d/wait.conf
	fi
else
	sudo mkdir -p /etc/systemd/system/dhcpcd.service.d/
	sudo cat > /tmp/_wait.conf << EOF
[Service]
ExecStart=
ExecStart=/usr/lib/dhcpcd5/dhcpcd -q -w
EOF
	sudo mv -f /tmp/_wait.conf /etc/systemd/system/dhcpcd.service.d/wait.conf
fi


# install usbmount
dpkg -s usbmount >/dev/null 2>&1

# install usbmount, if usbmount package is not installed
if [ $? -ne 0 ]; then
	sudo apt-get --assume-yes install usbmount
fi

# create backup of usbmount.conf, if it doesn't exist
if [ -f /etc/usbmount/usbmount.conf -a ! -f /etc/usbmount/usbmount.conf_backup ]; then
	sudo cp /etc/usbmount/usbmount.conf /etc/usbmount/usbmount.conf_backup
fi

# change usbmount.conf mountoptions, if not already changed. this is to ensure fat32 usb devices are automounted as r/w
if [ -f /etc/usbmount/usbmount.conf -a "$(grep -i "^MOUNTOPTIONS=" /etc/usbmount/usbmount.conf)" != "MOUNTOPTIONS=\"sync,noexec,nodev,noatime,nodiratime,nosuid,users,rw\"" ]; then
	sudo sed -e "s/^MOUNTOPTIONS=.*/MOUNTOPTIONS=\"sync,noexec,nodev,noatime,nodiratime,nosuid,users,rw\"/g" /etc/usbmount/usbmount.conf >/tmp/_usbmount.conf
	sudo mv -f /tmp/_usbmount.conf /etc/usbmount/usbmount.conf
fi

# change usbmount.conf fs_mountoptions, if not already changed. this is to ensure fat32 usb devices are automounted as r/w
if [ -f /etc/usbmount/usbmount.conf -a "$(grep -i "^FS_MOUNTOPTIONS=" /etc/usbmount/usbmount.conf)" != "FS_MOUNTOPTIONS=\"-fstype=vfat,umask=000\"" ]; then
	sudo sed -e "s/^FS_MOUNTOPTIONS=.*/FS_MOUNTOPTIONS=\"-fstype=vfat,umask=000\"/g" /etc/usbmount/usbmount.conf >/tmp/_usbmount.conf
	sudo mv -f /tmp/_usbmount.conf /etc/usbmount/usbmount.conf
fi

# patch device to mount as non private for automount usb devices
if [ -f /lib/systemd/system/systemd-udevd.service -a "$(grep -i "PrivateMounts=yes" /lib/systemd/system/systemd-udevd.service)" != "" ]; then
	sudo sed -e "s/PrivateMounts=yes/PrivateMounts=no/gi" /lib/systemd/system/systemd-udevd.service >/tmp/_systemd-udevd.service
	sudo mv -f /tmp/_systemd-udevd.service /lib/systemd/system/systemd-udevd.service
	sudo systemctl restart systemd-udevd.service
fi

# amiberry conf
if [ ! "$AMIBERRY_CONF_PATH" == "" -a -d "$AMIBERRY_CONF_PATH" ]; then
	# copy amiberry configs
	cp -R "$HSTWB_INSTALLER_ROOT/emulators/amiberry/configs/." "$AMIBERRY_CONF_PATH"

	# replace amiga hdd path placeholders with path
	find "$AMIBERRY_CONF_PATH" -name "hstwb-*.uae" -type f -exec sed -i "s/\\$\\[AMIGA_HDD_PATH\\]/$(echo "$AMIGA_HDD_PATH" | sed -e "s/\//\\\\\//g")/g" {} \;
	find "$AMIBERRY_CONF_PATH" -name "hstwb-*.uae" -type f -exec sed -i "s/\\$\\[AMIGA_KICKSTARTS_PATH\\]/$(echo "$AMIGA_KICKSTARTS_PATH" | sed -e "s/\//\\\\\//g")/g" {} \;
fi

# disable exit on eror
set +e

# show install dialog
dialog --clear --stdout \
--title "Success" \
--yesno "Successfully installed HstWB Installer.\n\nType hstwb and press enter from console at anytime to start HstWB Installer menu.\n\nDo you want to reboot and go through first time use steps now?" 0 0

# reboot to first time use, if yes is selected
if [ $? -eq 0 ]; then
	# create first time use trigger
	touch ~/.hstwb-installer/.first-time-use

 	reboot
fi
