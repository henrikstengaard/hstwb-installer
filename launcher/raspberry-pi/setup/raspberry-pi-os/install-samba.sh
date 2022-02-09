#!/bin/bash -e

# Install Samba
# -----------------
# Author: Henrik Noerfjand Stengaard
# Date: 2022-01-10
#
# A bash script for raspberry pi to install samba.

# fail, if amiberry emulator path is not set
if [ -z "$HSTWB_INSTALLER_ROOT" ]; then
        dialog --clear --title "ERROR" --msgbox "ERROR: HstWB Installer root path 'HSTWB_INSTALLER_ROOT' is not set!" 0 0
        exit 1
fi

# show install samba dialog
dialog --clear --stdout \
--title "Install Samba" \
--yesno "Installing Samba configures network shares for files transfer to and from Raspberry Pi users home directories using local area network connection.\n\nDo you want to install Samba?" 0 0

# exit, if no is selected
if [ $? -ne 0 ]; then
  exit
fi

# install samba
clear
echo "Installing Samba..."
echo ""
sudo apt-get --assume-yes install samba

# create backup of samba configuration file
if [ ! -f /etc/samba/smb.conf.bak ]; then
	sudo cp /etc/samba/smb.conf /etc/samba/smb.conf.bak
fi

# copy hstwb samba configuration file
sudo cp "$HSTWB_INSTALLER_ROOT/launcher/raspberry-pi/install/smb.conf" /etc/samba/smb.conf

# set raspberry as samba password for user
SMBPASS=raspberry
echo -ne "$SMBPASS\n$SMBPASS\n" | sudo smbpasswd -a -s $USER >/dev/null

# restart Samba
sudo service smbd restart

# disable exit on eror and check if dialog is installed
set +e

# check if ufw is installed
dpkg -s ufw >/dev/null 2>&1

# update ufw, if ufw is installed
if [ $? -ne 0 ]; then
	# update the firewall rules to allow Samba traffic
	sudo ufw allow samba
fi

# enable exit on eror
set -e

# get samba paths
SAMBA_PATHS=$(ifconfig | sed -En 's/127.0.0.1//;s/.*inet (addr:)?(([0-9]*\.){3}[0-9]*).*/Windows path: \\\\\2\\homes, macOS path: smb:\/\/\2\/homes\\n/p')

# show success dialog
dialog --title "Success" --msgbox "Successfully installed Samba.\n\nLogin with credentials:\nUsername: $USER\nPassword: $SMBPASS\n\nConnection:\n$SAMBA_PATHS\nOn Windows, open File Manager and enter connection path in location. On macOS, open Finder and from menu, click Go > Connect to Server and enter connection path.\n\nSamba password can be changed by running smbpasswd command from shell." 0 0
