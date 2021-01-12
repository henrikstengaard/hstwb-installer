#!/bin/bash -e

# Install UAE4ARM
# ---------------
# Author: Henrik Noerfjand Stengaard
# Date: 2021-01-12
#
# bash script to install uae4arm.


# fail, if uae4arm emulator path is not set
if [ -z "$UAE4ARM_EMULATOR_PATH" ]; then
        dialog --clear --title "ERROR" --msgbox "ERROR: UAE4ARM emulator path 'UAE4ARM_EMULATOR_PATH' is not set!" 0 0
        exit 1
fi

# show confirm dialog
dialog --clear --stdout \
--title "Install UAE4ARM" \
--yesno "This will download, compile and install UAE4ARM from github source code.\n\nWARNING: Existing UAE4ARM emulator in directory \"$UAE4ARM_EMULATOR_PATH\" will be overwritten!\n\nHard drives, floppies and configurations will stay untouched.\n\nDo you want to install UAE4ARM from github source code?" 0 0

# exit, if no is selected
if [ $? -ne 0 ]; then
  exit
fi

# paths
homedir=~
eval homedir=$homedir
uae4armdir="$UAE4ARM_EMULATOR_PATH/source"


# show select raspberry pi model dialog
choices=$(dialog --clear --stdout \
--title "Raspberry Pi model" \
--menu "Select Raspberry Pi model:" 0 0 0 \
1 "Raspberry Pi 4 / 400" \
2 "Raspberry Pi 3 (B+)" \
3 "Raspberry Pi 2" \
4 "Raspberry Pi 1 / Zero" \
5 "Exit")

clear

# exit, if cancelled
if [ -z "$choices" ]; then
  exit
fi

# choices
for choice in $choices; do
  case $choice in
    1)
	makeargs=""
	;;
    2)
	makeargs=""
	;;
    3)
      makeargs=""
      ;;
    4)
      makeargs="PLATFORM=rpi1"
      ;;
    5)
      exit
      ;;
  esac
done


# create uae4arm emulator path, if it doesn't exist
if [ ! -d "$$UAE4ARM_EMULATOR_PATH" ]; then
        mkdir -p "$UAE4ARM_EMULATOR_PATH"
fi

# clone uae4arm source code, if it doesn't exist
if [ ! -d "$uae4armdir" ]; then
        clear
        git clone https://github.com/Chips-fr/uae4arm-rpi "$uae4armdir"
        sleep 1
fi

# create uae4arm emulator directory, if it doesn't exist
#uae4armdir="$UAE4ARM_EMULATOR_PATH/source"
#if [ ! -d "$uae4armdir" ]; then#
#	mkdir -p "$uae4armdir"
#fi

# install required packages to compile uae4arm
echo ""
echo "Install required packages to compile UAE4ARM..."
sleep 1
sudo apt-get --assume-yes install libsdl1.2-dev libguichan-dev libsdl-ttf2.0-dev libsdl-gfx1.2-dev libxml2-dev libflac-dev libmpg123-dev libmpeg2-4-dev autoconf

pushd "$uae4armdir" >/dev/null
git reset --hard
git clean -xfd

git checkout master
git pull

# compile uae4arm
echo ""
echo "Compile UAE4ARM..."
sleep 1
make
make $makeargs
popd >/dev/null

# install uae4arm
echo ""
echo "Install UAE4ARM..."
sleep 1
cp "$uae4armdir/uae4arm" "$UAE4ARM_EMULATOR_PATH"
cp -R "$uae4armdir/conf" "$UAE4ARM_EMULATOR_PATH"
cp -R "$uae4armdir/data" "$UAE4ARM_EMULATOR_PATH"
cp -R "$uae4armdir/kickstarts" "$UAE4ARM_EMULATOR_PATH"
cp -R "$uae4armdir/savestates" "$UAE4ARM_EMULATOR_PATH"
cp -R "$uae4armdir/screenshots" "$UAE4ARM_EMULATOR_PATH"

# show success dialog
dialog --title "Success" --msgbox "Successfully installed UAE4ARM in directory \"$UAE4ARM_EMULATOR_PATH\"" 0 0
