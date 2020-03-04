#!/bin/bash

# Setup
# -----
# Author: Henrik Noerfjand Stengaard
# Date: 2020-03-04
#
# bash script to show system menu.

while true; do
	choices=$(dialog --clear --stdout \
	--title "System" \
	--menu "Select option:" 0 0 0 \
	1 "List FAT32 devices" \
	2 "Mount FAT32 devices" \
	3 "Repair FAT32 devices" \
	4 "Reboot" \
	5 "Shutdown" \
	6 "Exit")

	clear

	# exit, if cancelled
	if [ $? -ne 0 ]; then
		exit
	fi

	for choice in $choices; do
		case $choice in
		1)
			./list-fat32-devices.sh
			;;
		2)
			./mount-fat32-devices.sh
			;;
		3)
			./repair-fat32-devices.sh
			;;
		4)
			./reboot.sh
			;;
		5)
			./shutdown.sh
			;;
		6)
			exit
			;;
		esac
	done
done
