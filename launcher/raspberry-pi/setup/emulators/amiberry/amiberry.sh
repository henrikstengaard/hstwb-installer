#!/bin/bash

# Setup Amiberry
# --------------
# Author: Henrik Noerfjand Stengaard
# Date: 2022-01-02
#
# bash script to show setup amiberry menu.

while true; do
	choices=$(dialog --clear --stdout \
	--title "Setup Amiberry" \
	--menu "Select option:" 0 0 0 \
	1 "Install Amiberry" \
	2 "Disable Amiberry autostart" \
	3 "Exit")

	clear

	# exit, if cancelled
	if [ -z $choices ]; then
		exit
	fi

	for choice in $choices; do
		case $choice in
		1)
			./install-amiberry.sh
			;;
		2)
			./disable-amiberry-autostart.sh
			;;
		3)
			exit
			;;
		esac
	done
done
