#!/bin/bash -e

# Install FS-UAE
# --------------
# Author: Henrik Noerfjand Stengaard
# Date: 2022-01-27
#
# bash script to install fs-uae.


# fail, if fs-uae emulator path is not set
if [ -z "$FSUAE_EMULATOR_PATH" ]; then
        dialog --clear --title "ERROR" --msgbox "ERROR: FS-UAE emulator path 'FSUAE_EMULATOR_PATH' is not set!" 0 0
        exit 1
fi

# show confirm dialog
dialog --clear --stdout \
--title "Install FS-UAE" \
--yesno "This will download, compile and install FS-UAE from github source code.\n\nWARNING: Existing FS-UAE emulator in directory \"$FSUAE_EMULATOR_PATH\" will be overwritten!\n\nHard drives, floppies and configurations will stay untouched.\n\nDo you want to install FS-UAE from github source code?" 0 0

# exit, if no is selected
if [ $? -ne 0 ]; then
  exit
fi

# install required packages to compile fs-uae
echo ""
echo "Install required packages to compile FS-UAE..."
sleep 1
sudo apt-get --assume-yes install autoconf automake build-essential gettext \
libfreetype6-dev libglew-dev libglib2.0-dev libjpeg-dev libmpeg2-4-dev \
libopenal-dev libpng-dev libsdl2-dev libsdl2-ttf-dev libtool libxi-dev \
libxtst-dev zip zlib1g-dev

# paths
homedir=~
eval homedir=$homedir
fsuaedir="$FSUAE_EMULATOR_PATH/source"

# create fs-uae emulator path, if it doesn't exist
if [ ! -d "$FSUAE_EMULATOR_PATH" ]; then
        mkdir -p "$FSUAE_EMULATOR_PATH"
fi

# clone fs-uae source code, if it doesn't exist
if [ ! -d "$fsuaedir" ]; then
        clear
        git clone https://github.com/FrodeSolheim/fs-uae "$fsuaedir"
        sleep 1
fi

pushd "$fsuaedir" >/dev/null
#git reset --hard
#git clean -xfd

#if [ "$tag" != "" ]; then
#        git checkout tags/$tag
#else
#        git checkout $branch
#        git pull
#fi

# http://eab.abime.net/showthread.php?t=97979&page=2
# video_format = rgb565

# compile fs-uae
echo ""
echo "Compile FS-UAE..."
sleep 1
./bootstrap

# http://eab.abime.net/showthread.php?t=97979&page=2
CFLAGS="-g -O3 -march=armv8-a" \
CXXFLAGS="-g -O3 -march=armv8-a" \
./configure
make clean
make -j2
popd >/dev/null

# install fs-uae
echo ""
echo "Installing FS-UAE..."
sleep 1
cp "$fsuaedir/fs-uae" "$FSUAE_EMULATOR_PATH"
cp "$fsuaedir/fs-uae-device-helper" "$FSUAE_EMULATOR_PATH"
cp "$fsuaedir/fs-uae.dat" "$FSUAE_EMULATOR_PATH"
cp -R "$fsuaedir/data/." "$FSUAE_EMULATOR_PATH"

# create fs-uae config path, if it doesn't exist
if [ ! -d "$FSUAE_CONF_PATH" ]; then
        mkdir -p "$FSUAE_CONF_PATH"
fi

# show success dialog
dialog --title "Success" --msgbox "Successfully installed FS-UAE in directory \"$FSUAE_EMULATOR_PATH\"" 0 0


# show default amiga emulator dialog
dialog --clear --stdout \
--title "Default Amiga emulator" \
--yesno "Do you want to use FS-UAE as default Amiga emulator?" 0 0

# exit, if no is selected
if [ $? -ne 0 ]; then
  exit
fi

AMIGA_EMULATOR="fs-uae"

# add or update amiga emulator in config, if it doesn't exist
if [ "$(grep -i "AMIGA_EMULATOR=" ~/.hstwb-installer/config.sh)" == "" ]; then
        echo "export AMIGA_EMULATOR=\"$AMIGA_EMULATOR\"" >>~/.hstwb-installer/config.sh
else
        sed -e "s/^\(export AMIGA_EMULATOR=\).*/\1\"$(echo "$AMIGA_EMULATOR" | sed -e "s/\//\\\\\//g")\"/g" ~/.hstwb-installer/config.sh >~/.hstwb-installer/_config.sh
        mv -f ~/.hstwb-installer/_config.sh ~/.hstwb-installer/config.sh
fi

# add execute permission to config
chmod +x ~/.hstwb-installer/config.sh
