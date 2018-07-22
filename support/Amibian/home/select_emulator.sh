#!/bin/bash

# Select Emulator
# ---------------
# Author: Henrik Noerfjand Stengaard
# Date: 2018-04-04
#
# A bash script for Amibian to select emulator for HstWB Installer.


# show select emulator menu
choices=$(dialog --clear --stdout \
--title "Select Emulator" \
--menu "Select emulator to use for HstWB Installer:" 0 0 0 \
1 "Chips UAE4ARM for Raspberry Pi 1 and Zero" \
2 "Chips UAE4ARM for Raspberry Pi 2" \
3 "Chips UAE4ARM for Raspberry Pi 3" \
4 "Amiberry for Raspberry Pi 1 and Zero" \
5 "Amiberry for Raspberry Pi 2" \
6 "Amiberry for Raspberry Pi 3")

# exit, if cancelled
if [ $? -ne 0 ]; then
  exit
fi

clear

# choices
for choice in $choices; do
  case $choice in
    1)
      chipspi1
      ;;
    2)
      chipspi2
      ;;
    3)
      chipspi3
      ;;
    4)
      aberrypi1
      ;;
    5)
      aberrypi2
      ;;
    6)
      aberrypi3
      ;;
  esac
done