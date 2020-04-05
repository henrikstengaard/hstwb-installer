#!/bin/bash

# HstWB Installer Update
# ----------------------
# Author: Henrik Noerfjand Stengaard
# Date: 2020-04-04
#
# A bash script to update HstWB Installer launcher for Amibian.

# show update dialog
dialog --clear --stdout \
--title "Update HstWB Installer" \
--yesno "Do you want to update HstWB Installer to latest version?" 0 0

# exit, if no is selected
if [ $? -ne 0 ]; then
	exit 1
fi

# git pull
clear
echo "Updating HstWB Installer to latest version..."
git pull

# show reset and update, if update failed
if [ $? -ne 0 ]; then
	# pause
	read -p "Press enter to continue"

	# show reset and update dialog
	dialog --clear --stdout \
	--title "Reset and update HstWB Installer" \
	--yesno "Update failed possibly due to local changes. Do you want to reset any changes and update HstWB Installer to latest version?" 0 0

	# exit, if no is selected
	if [ $? -ne 0 ]; then
		exit 1
	fi

	# git reset, clean and pull
	clear
	echo "Resetting and updating HstWB Installer to latest version..."
	git reset --hard
	git clean -xfd
	git pull
fi

# pause
read -p "Press enter to continue"
