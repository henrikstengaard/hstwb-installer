#!/bin/bash

# Setup Amibian
# -------------
# Author: Henrik Noerfjand Stengaard
# Date: 2019-12-20
#
# bash script to show setup amibian menu.

while true; do
	choices=$(dialog --clear --stdout \
	--title "Setup Amibian" \
	--menu "Select option:" 0 0 0 \
	1 "Configure WiFi" \
	2 "Expand filesystem" \
	3 "Exit")

	clear

	# exit, if cancelled
	if [ $? -ne 0 ]; then
		exit
	fi

	for choice in $choices; do
		case $choice in
		1)
			wifi
			;;
		2)
			./expand.sh
			;;
		3)
			exit
			;;
		esac
	done
done
