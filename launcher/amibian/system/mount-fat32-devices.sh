#!/bin/bash

# Mount FAT32 devices
# -------------------
# Author: Henrik Noerfjand Stengaard
# Date: 2020-03-04
#
# A bash script to mount FAT32 devices to '/media/' using pmount.

# show mount fat32 devices dialog
dialog --clear --stdout \
--title "Mount FAT32 devices" \
--yesno "Mount FAT32 devices will go through devices with FAT32 filesystem and mount them to '/media/' using pmount, if they aren't already mounted. Use this if FAT32 formatted USB devices doesn't automatically appear in '/media/'.\n\nDo you want to mount FAT32 devices?" 0 0

# exit, if no is selected
if [ $? -ne 0 ]; then
	exit
fi

# iterate through devices with fat32 filesystem
while read devicepath; do
	echo "Found FAT32 device '$devicepath'..."

	# get mountpoint and skip, if not empty
	mountpoint=$(lsblk --list --paths --noheadings --output mountpoint $devicepath)
	if [ "$mountpoint" != "" ]; then
	        echo "Skip, already mounted as '$mountpoint'..."
		continue
	fi

	# mount fat32 device using pmount
	echo "Mounting FAT32 device '$devicepath'..."
	sudo pmount --sync --umask 000 $devicepath
done < <(lsblk --list --paths --noheadings --output name,fstype,size,state,mountpoint | grep -e "vfat" | awk '{print $1}')

# list fat32 devices
echo ""
./list-fat32-devices.sh
