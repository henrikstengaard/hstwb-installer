#!/bin/bash -e

# Install Amiberry
# ----------------
# Author: Henrik Noerfjand Stengaard
# Date: 2020-12-17
#
# bash script to install amiberry.

# show confirm dialog
dialog --clear --stdout \
--title "Install Amiberry" \
--yesno "This will download and install latest Amiberry from github source code.\n\nWARNING: Existing Amiberry emulator in Amiberry directory \"$AMIGA_HDD_PATH\" will be overwritten!\n\nDo you want to install latest Amiberry?" 0 0

# exit, if no is selected
if [ $? -ne 0 ]; then
  exit
fi

# show select raspberry pi model dialog
choices=$(dialog --clear --stdout \
--title "Raspberry Pi model" \
--menu "Select Raspberry Pi model:" 0 0 0 \
1 "Raspberry Pi 4" \
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
      makeargs="-j2 PLATFORM=rpi4"
      ;;
    2)
      makeargs="-j2 PLATFORM=rpi3"
      ;;
    3)
      makeargs="-j2 PLATFORM=rpi2"
      ;;
    4)
      makeargs="PLATFORM=rpi1"
      ;;
    5)
      exit
      ;;
  esac
done

# show select raspberry pi model dialog
choices=$(dialog --clear --stdout \
--title "SDL2 target" \
--menu "Select SDL2 target:" 0 0 0 \
1 "SDL2 + DispmanX (Best performance, Raspberry Pi platforms only)" \
2 "SDL2 (KMS, OpenGL, X11, etc.)" \
3 "Exit")

clear

# exit, if cancelled
if [ -z "$choices" ]; then
  exit
fi

# choices
for choice in $choices; do
  case $choice in
    2)
      makeargs="$makeargs-sdl2"
      ;;
    3)
      exit
      ;;
  esac
done

# paths
homedir=~
eval homedir=$homedir

# create amiberry directory, if it doesn't exist
amiberrydir="$homedir/amiga/emulators/amiberry"
if [ ! -d "$amiberrydir" ]; then
	mkdir -p "$amiberrydir"
fi

# install required packages to compile amiberry
echo ""
echo "Install required packages to compile Amiberry..."
sleep 1
#sudo apt-get install libsdl2-2.0-0 libsdl2-ttf-2.0-0 libsdl2-image-2.0-0 libxml2 flac mpg123 libmpeg2-4
sudo apt-get --assume-yes install libsdl2-dev libsdl2-ttf-dev libsdl2-image-dev libxml2-dev libflac-dev libmpg123-dev libpng-dev libmpeg2-4-dev

# clone or pull amiberry source code
echo ""
echo "Clone or pull latest Amiberry source code..."
sleep 1
if [ ! -d "$amiberrydir/source" ]; then
	git clone https://github.com/midwan/amiberry.git "$amiberrydir/source"
else
        git reset --hard
        git clean -xfd
        git pull
fi

# compile amiberry
echo ""
echo "Compile Amiberry..."
sleep 1
pushd "$amiberrydir/source" >/dev/null
make clean
make $makeargs
popd >/dev/null

# install amiberry
echo ""
echo "Install Amiberry..."
sleep 1
cp "$amiberrydir/source/amiberry" "$amiberrydir"
cp -R "$amiberrydir/source/conf" "$amiberrydir"
cp -R "$amiberrydir/source/data" "$amiberrydir"
cp -R "$amiberrydir/source/kickstarts" "$amiberrydir"
cp -R "$amiberrydir/source/savestates" "$amiberrydir"
cp -R "$amiberrydir/source/screenshots" "$amiberrydir"
cp -R "$amiberrydir/source/whdboot" "$amiberrydir"

# show success dialog
dialog --title "Success" --msgbox "Successfully installed Amiberry in directory \"$AMIGA_HDD_PATH\"" 0 0
