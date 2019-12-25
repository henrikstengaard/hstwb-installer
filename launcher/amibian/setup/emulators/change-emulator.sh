#!/bin/bash

# Change Emulator
# ---------------
# Author: Henrik Noerfjand Stengaard
# Date: 2019-12-20
#
# bash script to show change emulator menu.

while true; do
  choices=$(dialog --clear --stdout \
  --title "Change Emulator" \
  --menu "Select emulator to use:" 0 0 0 \
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
done
