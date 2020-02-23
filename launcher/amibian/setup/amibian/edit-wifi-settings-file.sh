#!/bin/bash

# Edit WiFi settings file
# -----------------------
# Author: Henrik Noerfjand Stengaard
# Date: 2020-02-23
#
# A bash script for Amibian to edit WiFi settings file.

sudo nano /etc/wpa_supplicant/wpa_supplicant.conf

# show expand filesystem dialog
dialog --clear --stdout \
--title "Reboot system" \
--yesno "Changes to WiFi settings file requires a reboot to be applied. Do you want to reboot the system?" 0 0

# exit, if no is selected
if [ $? -ne 0 ]; then
  exit
fi

echo "Rebooting..."
reboot
