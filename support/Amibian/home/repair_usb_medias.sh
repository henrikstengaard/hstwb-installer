#!/bin/bash

# Repair USB Medias
# -----------------
# Author: Henrik Noerfjand Stengaard
# Date: 2019-12-15
#
# A bash script for Amibian to repair usb medias with fat32 file system.


# iterate through usb medias with fat32 filesystem
while read devicepath; do
	echo "Repairing $devicepath..."

	# repair fat32 file system
	sudo dosfsck -w -a $devicepath
done < <(lsblk --list --paths --noheadings --output name,fstype,size,state,mountpoint | grep -e "vfat" -e "/media/usb" | awk '{print $1}')
