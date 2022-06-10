#!/bin/bash -e

# Change Amiga Emulator
# ---------------------
# Author: Henrik Noerfjand Stengaard
# Date: 2022-01-26
#
# bash script to show change amiga emulator menu.


# fail, if hstwb installer config doesn't exist
if [ ! -f ~/.hstwb-installer/config.sh ]; then
	dialog --clear --title "ERROR" --msgbox "ERROR: HstWB Installer config not found!\n\nPlease verify HstWB Installer is installed correctly." 0 0
	exit 1
fi

# show change amiga emulator dialog
choices=$(dialog --clear --stdout \
--title "Change Amiga Emulator" \
--menu "Select Amiga emulator to use:" 0 0 0 \
1 "Amiberry" \
2 "UAE4ARM" \
3 "FS-UAE" \
4 "Exit")

clear

# exit, if cancelled
if [ -z $choices ]; then
  exit
fi

AMIGA_EMULATOR="amiberry"

# choices
for choice in $choices; do
	case $choice in
		1)
			AMIGA_EMULATOR="amiberry"
			;;
		2)
			AMIGA_EMULATOR="uae4arm"
			;;
                3)
                        AMIGA_EMULATOR="fs-uae"
                        ;;
		4)
			exit
			;;
	esac
done


# add or update amiga emulator in config, if it doesn't exist
if [ "$(grep -i "AMIGA_EMULATOR=" ~/.hstwb-installer/config.sh)" == "" ]; then
	echo "export AMIGA_EMULATOR=\"$AMIGA_EMULATOR\"" >>~/.hstwb-installer/config.sh
else
        sed -e "s/^\(export AMIGA_EMULATOR=\).*/\1\"$(echo "$AMIGA_EMULATOR" | sed -e "s/\//\\\\\//g")\"/g" ~/.hstwb-installer/config.sh >~/.hstwb-installer/_config.sh
        mv -f ~/.hstwb-installer/_config.sh ~/.hstwb-installer/config.sh
fi

# add execute permission to config
chmod +x ~/.hstwb-installer/config.sh
