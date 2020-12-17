#!/bin/bash

# Delete HstWB Installer image cache
# ----------------------------------
# Author: Henrik Noerfjand Stengaard
# Date: 2020-04-04
#
# Bash script to delete HstWB Installer image cache

# show dialog
dialog --clear --stdout \
--title "Delete HstWB Install image cache" \
--yesno "Installing HstWB Installer image uses a cache for downloads and this can take a few GB of diskspace. The cache is used to avoid re-downloading HstWB Installer image when using 'Install HstWB Installer image'.\n\nThis will delete all downloaded HstWB Installer images and free diskspace.\n\nDo you want to delete HstWB Installer image cache?" 0 0

# exit, if no is selected
if [ $? -ne 0 ]; then
	exit
fi

# delete hstwb installer image cache
clear
echo "Delete HstWB Installer image cache..."
if [ -d ~/.hstwb-installer/uae4arm-image ]; then
	du -sh ~/.hstwb-installer/uae4arm-image
	rm -Rf ~/.hstwb-installer/uae4arm-image
fi

# pause
echo "Done"
read -p "Press enter to continue"
