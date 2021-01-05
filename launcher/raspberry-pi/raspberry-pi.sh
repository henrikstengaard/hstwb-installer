#!/bin/bash

# Raspberry Pi Launcher
# ------------------------
# Author: Henrik Noerfjand Stengaard
# Date: 2021-01-05
#
# bash script to show raspberry pi launcher.

# main menu
while true; do
	# show main menu
	choices=$(dialog --clear --stdout \
	--title "HstWB Installer for Raspbery Pi" \
	--menu "Select option:" 0 0 0 \
	1 "Run Amiga emulator" \
	2 "Midnight Commander" \
	3 "Setup" \
	4 "System" \
	5 "Update" \
	6 "About" \
	7 "Exit")

	clear

	# exit, if cancelled
	if [ -z $choices ]; then
		exit
	fi

	for choice in $choices; do
		case $choice in
		1)
			./run-amiga-emulator.sh
			;;
		2)
			./midnight-commander.sh
			;;
		3)
			pushd setup >/dev/null
			./setup.sh
			popd >/dev/null
			;;
		4)
			pushd system >/dev/null
			./system.sh
			popd >/dev/null
			;;
		5)
			./update.sh

			# restart script, if updated
			if [ $? -eq 0 ]; then
				exec "$0"
			fi
			;;
		6)
			./about.sh
			;;
		7)
			exit
			;;
		esac
	done
done
