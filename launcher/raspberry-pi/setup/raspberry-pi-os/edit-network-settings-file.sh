#!/bin/bash

# Edit network interfaces file
# ----------------------------
# Author: Henrik Noerfjand Stengaard
# Date: 2020-04-04
#
# bash script to edit network interfaces file.

sudo nano /etc/network/interfaces

# show expand filesystem dialog
dialog --clear --stdout \
--title "Reboot system" \
--yesno "Changes to network interfaces file requires a reboot to be applied. Do you want to reboot the system?" 0 0

# exit, if no is selected
if [ $? -ne 0 ]; then
  exit
fi

echo "Rebooting..."
reboot
