#!/bin/bash -e

# Install SDL2 KMSDRM
# -------------------
# Author: Henrik Noerfjand Stengaard
# Date: 2020-12-25
#
# bash script to install sdl2 kmsdrm required by amiberry.


# show confirm dialog
dialog --clear --stdout \
--title "Install SDL2 KMSDRM" \
--yesno "This will download, compile and install SDL2 KMSDRM from source code required by Amiberry.\n\nDo you want to download, compile and install SDL2 KMSDRM?" 0 0

# exit, if no is selected
if [ $? -ne 0 ]; then
  exit
fi

clear

# paths
home_dir=~
eval home_dir=$home_dir
tmp_dir="$home_dir/.tmp-sdl2-kmsdrm"

# delete temp directory, if it exists
if [ -d "$tmp_dir" ]; then
	rm -Rf "$tmp_dir"
fi

# create temp directory
mkdir -p "$tmp_dir"

# install required packages to compile sdl2
sudo apt-get --assume-yes install libsdl2-dev libsdl2-ttf-dev libsdl2-image-dev
sudo apt-get --assume-yes update && sudo apt-get --assume-yes upgrade
sudo apt-get --assume-yes install libfreetype6-dev libgl1-mesa-dev libgles2-mesa-dev libdrm-dev libgbm-dev libudev-dev libasound2-dev liblzma-dev libjpeg-dev libtiff-dev libwebp-dev git build-essential
sudo apt-get --assume-yes install gir1.2-ibus-1.0 libdbus-1-dev libegl1-mesa-dev libibus-1.0-5 libibus-1.0-dev libice-dev libsm-dev libsndio-dev libwayland-bin libwayland-dev libxi-dev libxinerama-dev libxkbcommon-dev libxrandr-dev libxss-dev libxt-dev libxv-dev x11proto-randr-dev x11proto-scrnsaver-dev x11proto-video-dev x11proto-xinerama-dev

# push temp directory to current directory
pushd "$tmp_dir" >/dev/null

# download and extract sdl2
echo ""
echo "Download and extract SDL2..."
sleep 1
wget https://libsdl.org/release/SDL2-2.0.12.tar.gz --no-check-certificate
tar xvzf SDL2-2.0.12.tar.gz

# compile and install sdl2
echo ""
echo "Compile and install SDL2..."
sleep 1
pushd SDL2-2.0.12 >/dev/null
./configure --enable-video-kmsdrm --disable-video-rpi && make -j$(nproc) && sudo make install
popd >/dev/null

# download and extract sdl2 image
echo ""
echo "Download and extract SDL2 image..."
sleep 1
wget https://www.libsdl.org/projects/SDL_image/release/SDL2_image-2.0.5.tar.gz --no-check-certificate
tar xvzf SDL2_image-2.0.5.tar.gz

# compile and install sdl2 image
echo ""
echo "Compile and install SDL2 image..."
sleep 1
pushd SDL2_image-2.0.5 >/dev/null
./configure && make -j$(nproc) && sudo make install
popd >/dev/null

# download and extract sdl2 ttf
echo ""
echo "Download and extract SDL2 ttf..."
sleep 1
wget https://www.libsdl.org/projects/SDL_ttf/release/SDL2_ttf-2.0.15.tar.gz --no-check-certificate
tar xvzf SDL2_ttf-2.0.15.tar.gz

# compile and install sdl2 ttf
echo ""
echo "Compile and install SDL2 ttf..."
sleep 1
pushd SDL2_ttf-2.0.15 >/dev/null
./configure && make -j$(nproc) && sudo make install
popd >/dev/null

# exit from temp directory
popd >/dev/null

# remove temp directory
rm -Rf "$tmp_dir"


# verify libsdl2 is installed
sudo ldconfig -v | grep libSDL2.so >/dev/null
if [ $? -ne 0 ]; then
        echo "Failed to install libSDL2!"
#       exit 1
fi

# verify libsdl2 image is installed
sudo ldconfig -v | grep libSDL2_image.so >/dev/null
if [ $? -ne 0 ]; then
	echo "Failed to install libSDL2_image!"
	exit 1
fi

# verify libsdl2 ttf is installed
sudo ldconfig -v | grep libSDL2_ttf.so >/dev/null
if [ $? -ne 0 ]; then
	echo "Failed to install libSDL2_ttf!"
	read -p "Press enter to continue"
	exit 1
fi


# show success dialog
dialog --title "Success" --msgbox "Successfully downloaded, compiled and installed SDL2 KMSDRM" 0 0
