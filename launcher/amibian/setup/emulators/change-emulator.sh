#!/bin/bash

# Change Emulator
# ---------------
# Author: Henrik Noerfjand Stengaard
# Date: 2020-02-23
#
# bash script to show change emulator menu.

# fail, if amibian version is not 1.4.1001
if [ "$AMIBIAN_VERSION" != "1.4.1001" ]; then
	# show success dialog
	dialog --clear --title "Change Emulator" --msgbox "Change emulator is not supported with Amibian v$AMIBIAN_VERSION!" 0 0
	exit
fi

# get selected emulator
SELECTEDEMULATOR="$(cat ~/amibian/help_texts/selected_emulator | awk '{$1=$1};1')"

# show change emulator dialog
choices=$(dialog --clear --stdout \
--title "Change Emulator" \
--menu "$SELECTEDEMULATOR. Change emulator to use:" 0 0 0 \
1 "Chips UAE4ARM for Raspberry Pi 1 and Zero" \
2 "Chips UAE4ARM for Raspberry Pi 2" \
3 "Chips UAE4ARM for Raspberry Pi 3" \
4 "Amiberry for Raspberry Pi 1 and Zero" \
5 "Amiberry for Raspberry Pi 2" \
6 "Amiberry for Raspberry Pi 3" \
7 "Exit")

clear

# exit, if cancelled
if [ $? -ne 0 ]; then
  exit
fi

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
    7)
      exit
      ;;
  esac
done
