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
	1 "System information" \
	2 "List FAT32 devices" \
	3 "Mount FAT32 devices" \
	4 "Repair FAT32 devices" \
	5 "Reboot" \
	6 "Shutdown" \
	7 "Exit")

	clear

	# exit, if cancelled
	if [ $? -ne 0 ]; then
		exit
	fi

	for choice in $choices; do
		case $choice in
		1)
			./system-information.sh
			;;
		2)
			./list-fat32-devices.sh
			;;
		3)
			./mount-fat32-devices.sh
			;;
		4)
			./repair-fat32-devices.sh
			;;
		5)
			./reboot.sh
			;;
		6)
			./shutdown.sh
			;;
		7)
			exit
			;;
		esac
	done
done
