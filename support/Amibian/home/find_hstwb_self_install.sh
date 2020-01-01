#!/bin/bash

# Find HstWB Self Install
# -----------------------
# Author: Henrik Noerfjand Stengaard
# Date: 2019-12-15
#
# A bash script for Amibian to find HstWB self install usb media.


function find_hstwb_self_install()
{
	# iterate through usb medias with fat32 filesystem
	while read usbmediapath; do
		echo "Checking $usbmediapath..."

		# skip usb media, if hstwb self install text file doesn't exist
		if [ ! -f "$usbmediapath/hstwb-self-install.txt" ]; then
			continue
		fi

		# delete media hstwb self install symlink, if it exists
		if [ -s "/media/hstwb-self-install" ]; then
			sudo rm -f "/media/hstwb-self-install"
		fi

		# create media hstwb self install symlink
		sudo ln -s "$usbmediapath" "/media/hstwb-self-install"

		# show success dialog
		dialog --clear --title "Success" --msgbox "Successfully found HstWB Self Install at USB media directory '$usbmediapath' and updated media symlink." 0 0

		break
	done < <(lsblk --list --paths --noheadings --output name,fstype,size,state,mountpoint | grep -e "vfat" -e "/media/usb" | awk '{print $4}')
}

# main loop
while true; do
	find_hstwb_self_install()

	# exit, if hstwb self install exists
	if [ -f "/media/hstwb-self-install/hstwb-self-install.txt" ]; then
		exit
	fi

	# show expand filesystem dialog
	dialog --clear --stdout \
	--title "HstWB Self Install not found" \
	--yesno "HstWB Self Install was not found. Do you want to retry?" 0 0

	# exit, if no is selected
	if [ $? -ne 0 ]; then
		clear
		exit
	fi
done