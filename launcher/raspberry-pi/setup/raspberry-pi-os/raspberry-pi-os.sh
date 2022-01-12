#!/bin/bash

# Setup Raspberry Pi OS
# ---------------------
# Author: Henrik Noerfjand Stengaard
# Date: 2022-01-12
#
# bash script to show setup raspberry pi os menu.

while true; do
	choices=$(dialog --clear --stdout \
	--title "Setup Raspberry Pi OS" \
	--menu "Select option:" 0 0 0 \
	1 "Raspberry Pi Software Configuration Tool (raspi-conf)" \
	2 "Change Volume" \
	3 "Change asound card" \
	4 "Set audio output to HDMI" \
	5 "Set audio output to Jack" \
	6 "Change boot" \
        7 "Force 1080p HDMI resolution" \
	8 "Install Samba" \
	9 "Expand filesystem" \
	10 "Exit")

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
                        ./change-asound-card.sh
                        ;;
 		4)
			./audio-output-hdmi.sh
			;;
		5)
			./audio-output-jack.sh
			;;
		6)
			./change-boot.sh
			;;
		7)
			./force-1080p-hdmi.sh
			;;
                8)
                        ./install-samba.sh
                        ;;
		9)
			./expand-filesystem.sh
			;;
		10)
			exit
			;;
		esac
	done
done
