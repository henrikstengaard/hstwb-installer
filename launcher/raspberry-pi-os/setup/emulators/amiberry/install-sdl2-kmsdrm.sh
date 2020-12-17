#!/bin/bash

# install required packages to compile sdl2
sudo apt-get install libsdl2-dev libsdl2-ttf-dev libsdl2-image-dev
sudo apt-get update && sudo apt-get upgrade
sudo apt-get install libfreetype6-dev libgl1-mesa-dev libgles2-mesa-dev libdrm-dev libgbm-dev libudev-dev libasound2-dev liblzma-dev libjpeg-dev libtiff-dev libwebp-dev git build-essential
sudo apt-get install gir1.2-ibus-1.0 libdbus-1-dev libegl1-mesa-dev libibus-1.0-5 libibus-1.0-dev libice-dev libsm-dev libsndio-dev libwayland-bin libwayland-dev libxi-dev libxinerama-dev libxkbcommon-dev libxrandr-dev libxss-dev libxt-dev libxv-dev x11proto-randr-dev x11proto-scrnsaver-dev x11proto-video-dev x11proto-xinerama-dev

# download and extract sdl2
wget https://libsdl.org/release/SDL2-2.0.12.tar.gz
tar xvzf SDL2-2.0.12.tar.gz

# compile sdl2
pushd SDL2-2.0.12
./configure --enable-video-kmsdrm --disable-video-rpi && make -j$(nproc) && sudo make install
popd

# download and extract sdl2 image
wget https://www.libsdl.org/projects/SDL_image/release/SDL2_image-2.0.5.tar.gz
tar xvzf SDL2_image-2.0.5.tar.gz

# compile sdl2 image
pushd SDL2_image-2.0.5
./configure && make -j$(nproc) && sudo make install
popd

# download and extract sdl2 ttf
wget https://www.libsdl.org/projects/SDL_ttf/release/SDL2_ttf-2.0.15.tar.gz
tar xvzf SDL2_ttf-2.0.15.tar.gz

# compile sdl2 ttf
pushd SDL2_ttf-2.0.15
./configure && make -j$(nproc) && sudo make install
popd



# verify  libs are installed

#pi@raspberrypi:~/sdl $ sudo ldconfig -v | grep image
#ldconfig: Can't stat /usr/local/lib/arm-linux-gnueabihf: No such file or directory
#ldconfig: Path `/usr/lib/arm-linux-gnueabihf' given more than once
#ldconfig: Path `/lib/arm-linux-gnueabihf' given more than once
#ldconfig: Path `/usr/lib/arm-linux-gnueabihf' given more than once
#ldconfig: Path `/usr/lib' given more than once
#ldconfig: /lib/arm-linux-gnueabihf/ld-2.28.so is the dynamic linker, ignoring
#
#        libSDL2_image-2.0.so.0 -> libSDL2_image.so
#ldconfig: /lib/ld-linux.so.3 is the dynamic linker, ignoring
#
#        libSDL2_image-2.0.so.0 -> libSDL2_image.so

