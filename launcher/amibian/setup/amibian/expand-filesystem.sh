#!/bin/bash

# Expand Filesystem
# -----------------
# Author: Henrik Noerfjand Stengaard
# Date: 2019-12-20
#
# A bash script for Amibian to expand filesystem.


# show expand filesystem dialog
dialog --clear --stdout \
--title "Expand Filesystem" \
--yesno "Do you want to expand filesystem?" 0 0

# exit, if no is selected
if [ $? -ne 0 ]; then
  exit
fi

# expand filesystem
echo "Expanding filesystem..."
echo ""
raspi-config --expand-rootfs
echo ""
read -rp "Press enter to reboot..."
reboot