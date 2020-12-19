#!/bin/bash

# Find HstWB Self Install
# -----------------------
# Author: Henrik Noerfjand Stengaard
# Date: 2020-12-18
#
# A bash script to find HstWB self install in '/media' and update '/media/hstwb-self-install' symlink to directory containing 'hstwb-self-install.txt' file.

# args
quiet=0


function find_hstwb_self_install()
{
	# iterate through usb medias with fat32 filesystem
	while read usbmediapath; do
		if [ $quiet -eq 0 ]; then
			echo "Checking $usbmediapath..."
		fi

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

		# show success dialog, if not quiet
		if [ $quiet -eq 0 ]; then
			dialog --clear --title "Success" --msgbox "Successfully found HstWB Self Install at USB media directory '$usbmediapath' and updated media symlink." 0 0
		fi

		break
	done < <(lsblk --list --paths --noheadings --output name,fstype,size,state,mountpoint | grep -e "vfat" -e "/media/" | awk '{print $4}')
}


# parse arguments
for i in "$@"
do
case $i in
    -q|--quiet)
    quiet=1
    shift
    ;;
    *)
        # unknown argument
    ;;
esac
done


# main loop
while true; do
	find_hstwb_self_install

	# exit, if hstwb self install exists
	if [ -f "/media/hstwb-self-install/hstwb-self-install.txt" ]; then
		exit
	fi

	# exit, if quiet
	if [ $quiet -eq 1 ]; then
		exit
	fi

	# show expand filesystem dialog
	dialog --clear --stdout \
	--title "HstWB Self Install not found" \
	--yesno "HstWB Self Install was not found on any usb devices.\n\nMake sure fat32 formatted usb device is inserted with HstWB Self install.\n\nDo you want to retry find HstWB self install?" 0 0

	# exit, if no is selected
	if [ $? -ne 0 ]; then
		clear
		exit
	fi
done
