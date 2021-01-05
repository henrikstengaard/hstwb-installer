#!/bin/bash -e

# Install Amiberry
# ----------------
# Author: Henrik Noerfjand Stengaard
# Date: 2020-12-25
#
# bash script to install amiberry.


# show confirm dialog
dialog --clear --stdout \
--title "Install Amiberry" \
--yesno "This will download, compile and install Amiberry from github source code.\n\nWARNING: Existing Amiberry emulator in Amiberry directory \"$AMIBERRY_EMULATOR_PATH\" will be overwritten!\n\nHard drives, floppies and configurations will stay untouched.\n\nDo you want to install Amiberry from github source code?" 0 0

# exit, if no is selected
if [ $? -ne 0 ]; then
  exit
fi

# paths
homedir=~
eval homedir=$homedir
amiberrydir="$AMIBERRY_EMULATOR_PATH/source"

# create amiberry emulator path, if it doesn't exist
if [ ! -d "$AMIBERRY_EMULATOR_PATH" ]; then
        mkdir -p "$AMIBERRY_EMULATOR_PATH"
fi

# clone amiberry source code, if it doesn't exist
if [ ! -d "$amiberrydir" ]; then
	clear
        git clone https://github.com/midwan/amiberry.git "$amiberrydir"
	sleep 1
fi


# show amiberry branch dialog
choices=$(dialog --clear --stdout \
--title "Amiberry branch" \
--menu "Select Amiberry branch:" 0 0 0 \
1 "Stable (master)" \
2 "Development (dev)" \
4 "Exit")

clear

# exit, if cancelled
if [ -z "$choices" ]; then
  exit
fi

branch="master"

# choices
for choice in $choices; do
	case $choice in
		1)
			branch="master"
			;;
		2)
			branch="dev"
			;;
		3)
			exit
			;;
	esac
done


# clone amiberry source code
if [ ! -d "$amiberrydir" ]; then
        clear
        git clone https://github.com/midwan/amiberry.git "$amiberrydir"
        sleep 1
fi

# show amiberry version dialog
choices=$(dialog --clear --stdout \
--title "Amiberry version" \
--menu "Select Amiberry version:" 0 0 0 \
1 "Latest version" \
2 "Specific version" \
3 "Exit")

tag=""

# choices
for choice in $choices; do
        case $choice in
                1)
                        tag=""
                        ;;
 		2)
			# build tags list
			pushd "$amiberrydir" >/dev/null
			git reset --hard
			git clean -xfd
			git checkout $branch
			git fetch --all --tags
			git tag -l | tac >/tmp/_amiberry-tags.txt
			sleep 1
			tags=()
			while read line; do
				tags+=($line)
			done < <(cat -n /tmp/_amiberry-tags.txt)
			popd >/dev/null

			# show select specific tag/version dialog
			tagchoice=$(dialog --clear --stdout --title "Specific tag/version" --menu "Select Specific tag/version:" 0 0 0 "${tags[@]}")

			clear

			# exit, if cancelled
			if [ -z "$tagchoice" ]; then
				exit
			fi

			tag=$(sed "${tagchoice[@]}!d" /tmp/_amiberry-tags.txt)
			rm /tmp/_amiberry-tags.txt
			;;
		4)
			exit
			;;
	esac
done


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


# create amiberry emulator directory, if it doesn't exist
amiberrydir="$AMIBERRY_EMULATOR_PATH/source"
if [ ! -d "$amiberrydir" ]; then
	mkdir -p "$amiberrydir"
fi

# install required packages to compile amiberry
echo ""
echo "Install required packages to compile Amiberry..."
sleep 1
#sudo apt-get install libsdl2-2.0-0 libsdl2-ttf-2.0-0 libsdl2-image-2.0-0 libxml2 flac mpg123 libmpeg2-4
sudo apt-get --assume-yes install libsdl2-dev libsdl2-ttf-dev libsdl2-image-dev libxml2-dev libflac-dev libmpg123-dev libpng-dev libmpeg2-4-dev

pushd "$amiberrydir" >/dev/null
git reset --hard
git clean -xfd

if [ "$tag" != "" ]; then
	git checkout tags/$tag
else
	git checkout $branch
	git pull
fi

# compile amiberry
echo ""
echo "Compile Amiberry $branch $tag..."
sleep 1
make clean
make $makeargs
popd >/dev/null

# install amiberry
echo ""
echo "Install Amiberry $branch $tag..."
sleep 1
cp "$amiberrydir/amiberry" "$AMIBERRY_EMULATOR_PATH"
cp -R "$amiberrydir/conf" "$AMIBERRY_EMULATOR_PATH"
cp -R "$amiberrydir/data" "$AMIBERRY_EMULATOR_PATH"
cp -R "$amiberrydir/kickstarts" "$AMIBERRY_EMULATOR_PATH"
cp -R "$amiberrydir/savestates" "$AMIBERRY_EMULATOR_PATH"
cp -R "$amiberrydir/screenshots" "$AMIBERRY_EMULATOR_PATH"
cp -R "$amiberrydir/whdboot" "$AMIBERRY_EMULATOR_PATH"

# show success dialog
dialog --title "Success" --msgbox "Successfully installed Amiberry $branch $tag in directory \"$AMIBERRY_EMULATOR_PATH\"" 0 0
