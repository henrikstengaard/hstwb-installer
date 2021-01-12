#!/bin/bash

# Setup UAE4ARM
# -------------
# Author: Henrik Noerfjand Stengaard
# Date: 2021-01-12
#
# bash script to show setup uae4arm menu.

while true; do
	choices=$(dialog --clear --stdout \
	--title "Setup UAE4ARM" \
	--menu "Select option:" 0 0 0 \
	1 "Install UAE4ARM" \
	2 "Disable UAE4ARM autostart" \
	3 "Exit")

	clear

	# exit, if cancelled
	if [ -z $choices ]; then
		exit
	fi

	for choice in $choices; do
		case $choice in
		1)
			./install-uae4arm.sh
			;;
		2)
			./disable-uae4arm-autostart.sh
			;;
		3)
			exit
			;;
		esac
	done
done
