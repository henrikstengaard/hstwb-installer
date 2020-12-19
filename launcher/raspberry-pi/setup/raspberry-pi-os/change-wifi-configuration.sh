#!/bin/bash

# Change WiFi Configuration
# -------------------------
# Author: Henrik Noerfjand Stengaard
# Date: 2019-12-30
#
# A bash script for Amibian to change wifi configuration.

function scan_ssid()
{
	clear
	echo "Scanning for WiFi network SSID's..."
	sleep 1

	# scan wlan0 and get ssid's
	iwlist wlan0 scan | awk -F ':' '/ESSID:/ {print $2;}' | sed -e s/\"//g >//tmp/ssids

	# return error, if iwlist doesn't return error code 0
	if [ $? -ne 0 ]; then
		# show error dialog
		dialog --clear --title "Change WiFi configuration" --msgbox "ERROR: An error occured while scanning for WiFi network SSID's. Please try again or restart and try again." 0 0
		return 1
	fi

	# build menu options
	COUNT=0
	declare -a OPTIONS
	while read -r line; do
		OPTIONS+=($((++COUNT)) "$line")
	done < /tmp/ssids

	# show select wifi ssid dialog
	choices=$(dialog --clear --stdout --title "Change WiFi configuration" --menu "Select WiFi network SSID to connect to:" 0 0 0 "${OPTIONS[@]}")

	# return error, if dialog is cancelled
	if [ $choices -le 0 ]; then
		return 1
	fi

	# get selected ssid
	SSID="$(sed "$choices!d" /tmp/ssids)"

	# delete temp ssids
	rm /tmp/ssids

	return 0
}

function update_conf()
{
	# create wpa supplicant with ssid and password
	echo -en "network={\nssid=\"$SSID\"\npsk=\"$PASSWORD\"\n}\n" >/etc/wpa_supplicant/wpa_supplicant.conf

	# show success dialog
	dialog --clear --title "Change WiFi configuration" --msgbox "WiFI configuration successfully changed to SSID \"$SSID\".\n\nTo use the changed WiFi configuration, the system will now reboot." 0 0

	# rebooting
	echo "Rebooting..."
	reboot
}

function enter_ssid()
{
	# get ssid
	SSID="$(dialog --clear --stdout --title "Change WiFi configuration" --inputbox "Enter SSID:" 0 0)"

	# return error, if dialog is cancelled
	if [ $? -ne 0 ]; then
		return 1
	fi

	return 0
}

function enter_password()
{
	# get password for ssid
	PASSWORD="$(dialog --clear --stdout --title "Change WiFi configuration" --insecure --passwordbox "Enter password for SSID "$SSID":" 0 0)"

	# return error, if dialog is cancelled
	if [ $? -ne 0 ]; then
		return 1
	fi

	return 0
}

# show wifi dialog
dialog --clear --stdout \
--title "Change WiFi configuration" \
--yesno "Change WiFi configuration can scan for available WiFi network SSID's and lists them in a menu for selection. Afterwards it will prompt for selected SSID password. It's also possible to manually enter WiFi network SSID.\n\nWARNING: This will overwrite existing WiFi configuration and reboot!\n\nDo you want to change WiFi configuration?" 0 0

# exit, if no is selected
if [ $? -ne 0 ]; then
  exit
fi

# menu
while true; do
	choices=$(dialog --clear --stdout \
	--title "Change WiFi configuration" \
	--menu "Select option:" 0 0 0 \
	1 "Scan and select WiFi network SSID" \
	2 "Manually type WiFi network SSID" \
	3 "Exit")

	clear

	# exit, if cancelled
	if [ $? -ne 0 ]; then
		exit
	fi

	for choice in $choices; do
		case $choice in
		1)
			if ! scan_ssid; then
				break
			fi

			if ! enter_password; then
				break
			fi

			update_conf
			;;
		2)
			if ! enter_ssid; then
				break
			fi
			if ! enter_password; then
				break
			fi

			update_conf
			;;
		3)
			exit
			;;
		esac
	done
done
