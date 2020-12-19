#!/bin/bash

# Change Boot
# -----------
# Author: Henrik Noerfjand Stengaard
# Date: 2020-12-19
#
# bash script to change boot menu.

function change_boot()
{
	HSTWB_INSTALLER_BOOT="$1"
	sed -e "s/^\(export HSTWB_INSTALLER_BOOT=\).*/\1\"$(echo "$HSTWB_INSTALLER_BOOT" | sed -e "s/\//\\\\\//g")\"/g" ~/.hstwb-installer/config.sh >~/.hstwb-installer/_config.sh
	mv -f ~/.hstwb-installer/_config.sh ~/.hstwb-installer/config.sh
	chmod +x ~/.hstwb-installer/config.sh
}

# fail, if hstwb installer config file doesn't exist
if [ ! -f ~/.hstwb-installer/config.sh ]; then
	echo "ERROR: HstWB Installer config \"~/.hstwb-installer/config.sh\" doesn't exist"
	exit 1
fi

choices=$(dialog --clear --stdout \
--title "Change boot" \
--menu "Select what to start at boot:" 0 0 0 \
1 "Emulator" \
2 "HstWB Installer" \
3 "Amibian menu" \
4 "Exit")

clear

# exit, if cancelled
if [ -z $choices ]; then
  exit
fi

# choices
for choice in $choices; do
  case $choice in
    1)
      change_boot emulator
      ;;
    2)
      change_boot hstwb
      ;;
    3)
      change_boot menu
      ;;
    4)
      exit
      ;;
  esac
done
