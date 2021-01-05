#!/bin/bash

# Reboot
# ------
# Author: Henrik Noerfjand Stengaard
# Date: 2021-01-05
#
# A bash script for raspberry pi os to reboot system.


# show reboot dialog
dialog --clear --stdout \
--title "Reboot" \
--yesno "Do you want to reboot system?" 0 0

# exit, if no is selected
if [ $? -ne 0 ]; then
  exit
fi

echo "Rebooting..."
sudo reboot
