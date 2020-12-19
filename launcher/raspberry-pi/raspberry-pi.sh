#!/bin/bash

# Raspberry Pi Launcher
# ------------------------
# Author: Henrik Noerfjand Stengaard
# Date: 2020-12-19
#
# bash script to show raspberry pi launcher.

# main menu
while true; do
	# show main menu
	choices=$(dialog --clear --stdout \
	--title "HstWB Installer for Raspbery Pi" \
	--menu "Select option:" 0 0 0 \
	1 "Run Amiga emulator" \
	2 "Run Amiga emulator without autostart" \
	3 "Midnight Commander" \
	4 "Setup" \
	5 "System" \
	6 "Update" \
	7 "About" \
	8 "Exit")

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
			./run-amiga-emulator.sh --no-autostart
			;;
		3)
			./midnight-commander.sh
			;;
		4)
			pushd setup >/dev/null
			./setup.sh
			popd >/dev/null
			;;
		5)
			pushd system >/dev/null
			./system.sh
			popd >/dev/null
			;;
		6)
			./update.sh

			# restart script, if updated
			if [ $? -eq 0 ]; then
				exec "$0"
			fi
			;;
		7)
			./about.sh
			;;
		8)
			exit
			;;
		esac
	done
done
