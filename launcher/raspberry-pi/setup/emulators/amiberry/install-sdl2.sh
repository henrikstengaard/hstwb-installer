#!/bin/bash -e

# Install SDL2
# ------------
# Author: Henrik Noerfjand Stengaard
# Date: 2022-01-12
#
# bash script to install sdl2 required by amiberry.

SDL2_VERSION=2.0.18

# show confirm dialog
dialog --clear --stdout \
--title "Install SDL2" \
--yesno "This will download, compile and install SDL2 v$SDL2_VERSION from source code required by Amiberry.\n\nDo you want to download, compile and install SDL2?" 0 0

# exit, if no is selected
if [ $? -ne 0 ]; then
  exit
fi

clear

# show select sdl2 configuration dialog
choices=$(dialog --clear --stdout \
--title "SDL2 configuration" \
--menu "Select SDL2 configuration:" 0 0 0 \
1 "Default" \
2 "Optimized for Raspberry Pi 4 / 400, 3 (B+)" \
3 "Optimized for Raspberry Pi 2, 1 / Zero" \
4 "Exit")

clear

# exit, if cancelled
if [ -z "$choices" ]; then
  exit
fi

configureargs=""

# choices
for choice in $choices; do
  case $choice in
    2)
      configureargs="--enable-video-kmsdrm"
      ;;
    3)
      configureargs="--enable-video-kmsdrm --enable-video-opengles --disable-video-rpi --disable-pulseaudio --disable-esd --disable-video-wayland --disable-video-opengl --disable-video-x11"
      ;;
    4)
      exit
      ;;
  esac
done


# paths
home_dir=~
eval home_dir=$home_dir
tmp_dir="$home_dir/.tmp-sdl2"

# delete temp directory, if it exists
if [ -d "$tmp_dir" ]; then
	rm -Rf "$tmp_dir"
fi

# create temp directory
mkdir -p "$tmp_dir"

# install required packages to compile sdl2
#sudo apt-get --assume-yes install libsdl2-dev libsdl2-ttf-dev libsdl2-image-dev
sudo apt-get --assume-yes update && sudo apt-get --assume-yes upgrade
#sudo apt-get --assume-yes install libfreetype6-dev libgl1-mesa-dev libgles2-mesa-dev libdrm-dev libgbm-dev libudev-dev libasound2-dev liblzma-dev libjpeg-dev libtiff-dev libwebp-dev git build-essential
#sudo apt-get --assume-yes install gir1.2-ibus-1.0 libdbus-1-dev libegl1-mesa-dev libibus-1.0-5 libibus-1.0-dev libice-dev libsm-dev libsndio-dev libwayland-bin libwayland-dev libxi-dev libxinerama-dev libxkbcommon-dev libxrandr-dev libxss-dev libxt-dev libxv-dev x11proto-randr-dev x11proto-scrnsaver-dev x11proto-video-dev x11proto-xinerama-dev
sudo apt-get --assume-yes install gcc g++ debhelper libasound2-dev libdbus-1-dev libegl1-mesa-dev libdrm-dev libgbm-dev libgl1-mesa-dev libgles-dev libpulse-dev libudev-dev libibus-1.0-dev libsndio-dev libwayland-dev libx11-dev libxcursor-dev libxext-dev libxfixes-dev libxi-dev libxinerama-dev libxkbcommon-dev libxrandr-dev libxss-dev libxxf86vm-dev libxt-dev libxv-dev libsamplerate0-dev wayland-protocols


# push temp directory to current directory
pushd "$tmp_dir" >/dev/null

# download and extract sdl2
echo ""
echo "Download and extract SDL2..."
sleep 1
wget https://libsdl.org/release/SDL2-$SDL2_VERSION.tar.gz --no-check-certificate
tar xvzf SDL2-$SDL2_VERSION.tar.gz

# compile and install sdl2
echo ""
echo "Compile and install SDL2..."
sleep 1
pushd SDL2-$SDL2_VERSION >/dev/null
./configure $configureargs && make -j$(nproc) && sudo make install
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
dialog --title "Success" --msgbox "Successfully downloaded, compiled and installed SDL2 v$SDL2_VERSION" 0 0
