#!/bin/bash

# Repair USB Medias
# -----------------
# Author: Henrik Noerfjand Stengaard
# Date: 2020-03-04
#
# A bash script to repair FAT32 devices using dosfsck.

# show repair fat32 devices dialog
dialog --clear --stdout \
--title "Repair FAT32 devices" \
--yesno "Repair FAT32 devices will go through '/media/' devices with FAT32 filesystem and run fsck to repair filesystem. Use this if FAT32 formatted USB devices doesn't mount properly.\n\nDo you want to repair FAT32 devices?" 0 0

# exit, if no is selected
if [ $? -ne 0 ]; then
	exit
fi

# iterate through devices with fat32 filesystem and run dosfsck
while read devicepath; do
	echo "Repairing $devicepath..."

	# repair fat32 file system
	sudo dosfsck -w -a $devicepath
done < <(lsblk --list --paths --noheadings --output name,fstype,size,state,mountpoint | grep -e "vfat" -e "/media/" | awk '{print $1}')

# list fat32 devices
echo ""
./list-fat32-devices.sh
