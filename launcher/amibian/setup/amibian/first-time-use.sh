#!/bin/bash -e

# First Time Use
# --------------
# Author: Henrik Noerfjand Stengaard
# Date: 2019-12-29
#
# Bash script for first time use of Amibian.

# show first time use dialog, if its trigger doesnt exist
if [ ! -f ~/.hstwb-installer/.first-time-use-dialog ]; then
	# show first time use dialog
	dialog --clear --stdout \
	--title "First time use" \
	--yesno "First time use will go through initial steps to get Amibian, emulators and HstWB Installer up and running. Do you want to go through first time use steps?" 0 0

	# delete first time use dialog trigger
	touch ~/.hstwb-installer/.first-time-use-dialog

	# exit, if no is selected
	if [ $? -ne 0 ]; then
		exit
	fi
fi

# expand filesystem, if its trigger exists
if [ ! -f ~/.hstwb-installer/.expand-filesystem ]; then
	touch ~/.hstwb-installer/.expand-filesystem
	$HSTWBINSTALLERROOT/launcher/amibian/setup/amibian/expand-filesystem.sh
fi

# find hstwb self install
$HSTWBINSTALLERROOT/launcher/amibian/setup/hstwb-installer/find-hstwb-self-install.sh

# install kickstart rom
$HSTWBINSTALLERROOT/launcher/amibian/setup/emulators/install-kickstart-rom.sh -i -id=/media/hstwb-self-install/kickstart -kd=/root/amibian/amiga_files/kickstarts

# change emulator
$HSTWBINSTALLERROOT/launcher/amibian/setup/emulators/change-emulator.sh

# change wifi
$HSTWBINSTALLERROOT/launcher/amibian/setup/amibian/change-wifi.sh

# install hstwb installer image
$HSTWBINSTALLERROOT/launcher/amibian/setup/hstwb-installer/install-hstwb-installer-image.sh

# delete triggers
if [ -f ~/.hstwb-installer/.first-time-use-dialog ]; then
	rm ~/.hstwb-installer/.first-time-use-dialog
fi
if [ -f ~/.hstwb-installer/.first-time-use ]; then
	rm ~/.hstwb-installer/.first-time-use
fi
if [ -f ~/.hstwb-installer/.expand-filesystem ]; then
	rm ~/.hstwb-installer/.expand-filesystem
fi
