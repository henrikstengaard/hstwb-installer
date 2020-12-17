#!/bin/bash

# Setup Emulators
# ---------------
# Author: Henrik Noerfjand Stengaard
# Date: 2020-12-17
#
# bash script to show setup emulators menu.

while true; do
	choices=$(dialog --clear --stdout \
	--title "Setup Emulators" \
	--menu "Select option:" 0 0 0 \
        1 "Amiberry" \
	2 "Install Kickstart rom" \
	3 "Exit")

	clear

	# exit, if cancelled
	if [ $? -ne 0 ]; then
		exit
	fi

	for choice in $choices; do
		case $choice in
		1)
                        pushd amiberry >/dev/null
                        ./amiberry.sh
                        popd >/dev/null
			;;
		2)
			./install-kickstart-rom.sh
			;;
		3)
			exit
			;;
		esac
	done
done
