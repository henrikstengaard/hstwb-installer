#!/bin/bash

# Mount FAT32 devices
# -------------------
# Author: Henrik Noerfjand Stengaard
# Date: 2020-04-04
#
# A bash script to mount FAT32 devices to '/media/' using pmount.

# check if pmount is installed
dpkg -s pmount >/dev/null 2>&1

# show install pmount, if pmount is not installed
if [ $? -ne 0 ]; then
	# show install pmount dialog
	dialog --clear --stdout \
	--title "Install pmount" \
	--yesno "Pmount is not installed and is required by mount FAT32 devices.\n\nDo you want to install pmount?" 0 0

	# exit, if no is selected
	if [ $? -ne 0 ]; then
		exit
	fi

	# install pmount
	sudo apt-get install pmount
fi

quiet=0

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

# show dialog, if not quiet
if [ $quiet -eq 0 ]; then
	# show mount fat32 devices dialog
	dialog --clear --stdout \
	--title "Mount FAT32 devices" \
	--yesno "Mount FAT32 devices will go through devices with FAT32 filesystem and mount them to '/media/' using pmount, if they aren't already mounted. Use this if FAT32 formatted USB devices doesn't automatically appear in '/media/'.\n\nDo you want to mount FAT32 devices?" 0 0

	# exit, if no is selected
	if [ $? -ne 0 ]; then
		exit
	fi
fi

# iterate through devices with fat32 filesystem
clear
mounted_devices=()
while read devicepath; do
	# get mountpoint and skip, if not empty
	mountpoint=$(lsblk --list --paths --noheadings --output mountpoint $devicepath)
	if [ "$mountpoint" != "" ]; then
		continue
	fi

	# mount fat32 device using pmount
	mounted_devices+=($devicepath)
	sudo pmount --sync --umask 000 $devicepath
done < <(lsblk --list --paths --noheadings --output name,fstype,size,state,mountpoint | grep -e "vfat" | awk '{print $1}')

# show dialog with mounted devices, if any
if [ ${#mounted_devices[@]} -ne 0 ]; then
	dialog --clear --title "Mount FAT32 devices" --msgbox "Successfully mounted FAT32 devices:\n'${mounted_devices[@]}'" 0 0
fi

# list fat32 devices, if not quiet
if [ $quiet -eq 0 ]; then
	./list-fat32-devices.sh
fi
