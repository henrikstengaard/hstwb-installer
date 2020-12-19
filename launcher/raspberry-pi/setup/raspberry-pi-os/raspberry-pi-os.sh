#!/bin/bash

# Setup Raspberry Pi OS
# ---------------------
# Author: Henrik Noerfjand Stengaard
# Date: 2020-12-19
#
# bash script to show setup raspberry pi os menu.

while true; do
	choices=$(dialog --clear --stdout \
	--title "Setup Raspberry Pi OS" \
	--menu "Select option:" 0 0 0 \
	1 "Raspberry Pi Software Configuration Tool (raspi-conf)" \
	2 "Change Volume" \
	3 "Set audio output to HDMI" \
	4 "Set audio output to Jack" \
	5 "Change boot" \
	6 "Expand filesystem" \
	7 "Exit")

	clear

	# exit, if cancelled
	if [ -z $choices ]; then
		exit
	fi

	for choice in $choices; do
		case $choice in
		1)
			sudo raspi-config
			;;
		2)
			sudo alsamixer
			;;
		3)
			./audio-output-hdmi.sh
			;;
		4)
			./audio-output-jack.sh
			;;
		5)
			./change-boot.sh
			;;
		6)
			./expand-filesystem.sh
			;;
		7)
			exit
			;;
		esac
	done
done
