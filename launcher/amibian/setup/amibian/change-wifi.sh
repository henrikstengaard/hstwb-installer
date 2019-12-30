#!/bin/bash

# Change WiFi
# -----------
# Author: Henrik Noerfjand Stengaard
# Date: 2019-12-30
#
# A bash script for Amibian to change wifi network configuration.

# show wifi dialog
dialog --clear --stdout \
--title "Change WiFi" \
--yesno "Change WiFi scans for available WiFi network SSID's and lists them in a menu for selection. It will prompt for password to selected SSID. WARNING: This will overwrite existing WiFi configuration and reboot! Do you want to change WiFi configuration?" 0 0

# exit, if no is selected
if [ $? -ne 0 ]; then
  exit
fi

# create wifi ssid options
iwlist wlan0 scan | awk -F ':' '/ESSID:/ {print $2;}' | sed -e s/\"//g >/tmp/ssids

# fail, iwlist doesn't return error code 0
if [ $? -ne 0 ]; then
  exit
fi

INDEX=1
OPTIONS=""
while IFS= read -r line; do
	OPTIONS="$OPTIONS $INDEX "$line""
	let INDEX=INDEX+1
done <<< "$(cat /tmp/ssids)"

# show select wifi ssid dialog
choices=$(dialog --clear --stdout --title "Change WiFi" --menu "Select WiFi SSID to connect to:" 0 0 0 $OPTIONS)

# exit, if cancelled
if [ $choices -le 0 ]; then
  exit
fi

# get selected ssid
SSID="$(sed "$choices!d" /tmp/ssids)"

# get password for selected ssid
PASSWORD="$(dialog --clear --stdout --title "Change WiFi" --insecure --passwordbox "Enter password for SSID "$SSID":" 0 0)"

# create wpa supplicant with ssid and password
echo -en "network={\nssid=\"$SSID\"\npsk=\"$PASSWORD\"\n}\n" >/etc/wpa_supplicant/wpa_supplicant.conf

# rebooting
echo "Rebooting..."
reboot
