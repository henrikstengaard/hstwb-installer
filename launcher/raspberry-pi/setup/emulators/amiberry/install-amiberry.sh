#!/bin/bash -e

# Install Amiberry
# ----------------
# Author: Henrik Noerfjand Stengaard
# Date: 2022-01-13
#
# bash script to install amiberry.


# select raspberry pi model
function select_raspberry_pi_model()
{
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
	      RASPBERRY_PI_MODEL="rpi4"
	      ;;
	    2)
	      RASPBERRY_PI_MODEL="rpi3"
	      ;;
	    3)
	      RASPBERRY_PI_MODEL="rpi2"
	      ;;
	    4)
	      RASPBERRY_PI_MODEL="rpi1"
	      ;;
	    5)
	      exit
	      ;;
	  esac
	done
}

# select operating system
function select_operating_system()
{
        # show select operating system dialog
        choices=$(dialog --clear --stdout \
        --title "Operating system" \
        --menu "Select operating system:" 0 0 0 \
        1 "32-bit" \
        2 "64-bit" \
        3 "Exit")

        clear

        # exit, if cancelled
        if [ -z "$choices" ]; then
          exit
        fi

        # choices
        for choice in $choices; do
          case $choice in
            1)
              OPERATING_SYSTEM="32"
              ;;
            2)
              OPERATING_SYSTEM="64"
              ;;
            3)
              exit
              ;;
          esac
        done
}

# select sdl2 target
function select_sdl2_target()
{
	# show select sdl2 target dialog
	choices=$(dialog --clear --stdout \
	--title "SDL2 target" \
	--menu "Select SDL2 target:" 0 0 0 \
	1 "SDL2" \
	2 "SDL2 + DispmanX" \
	3 "Exit")

	clear

	# exit, if cancelled
	if [ -z "$choices" ]; then
	  exit
	fi

	# choices
	for choice in $choices; do
	  case $choice in
	    1)
	      SDL2_TARGET="sdl2"
	      ;;
            2)
              SDL2_TARGET="dmx"
              ;;
 	    3)
	      exit
	      ;;
	  esac
	done
}


# fail, if amiberry emulator path is not set
if [ -z "$AMIBERRY_EMULATOR_PATH" ]; then
        dialog --clear --title "ERROR" --msgbox "ERROR: Amiberry emulator path 'AMIBERRY_EMULATOR_PATH' is not set!" 0 0
        exit 1
fi

# show confirm dialog
dialog --clear --stdout \
--title "Install Amiberry" \
--yesno "This will download, compile and install Amiberry from github source code.\n\nWARNING: Existing Amiberry emulator in Amiberry directory \"$AMIBERRY_EMULATOR_PATH\" will be overwritten!\n\nHard drives, floppies and configurations will stay untouched.\n\nDo you want to install Amiberry from github source code?" 0 0

# exit, if no is selected
if [ $? -ne 0 ]; then
  exit
fi

# select raspberyr pi model
RASPBERRY_PI_MODEL=""
select_raspberry_pi_model

# select operating system, if raspberry pi 4 / 400, 3 (B+)
OPERATING_SYSTEM="32"
if [ "$RASPBERRY_PI_MODEL" = "rpi4" -o "$RASPBERRY_PI_MODEL" = "rpi3" ]; then
	select_operating_system
fi

# select sdl2 target
SDL2_TARGET=""
select_sdl2_target

# build platform
PLATFORM="$RASPBERRY_PI_MODEL"

if [ "$OPERATING_SYSTEM" = "64" ]; then
        PLATFORM="$PLATFORM-$OPERATING_SYSTEM-$SDL2_TARGET"
else
	if [ "$SDL2_TARGET" = "sdl2" ]; then
		PLATFORM="$PLATFORM-$SDL2_TARGET"
	fi
fi

# build makeargs
MAKEARGS="PLATFORM=$PLATFORM"
if [ "$RASPBERRY_PI_MODEL" != "rpi1" ]; then
	MAKEARGS="-j2 $MAKEARGS"
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
sudo apt-get --assume-yes install libsdl2-dev libsdl2-ttf-dev libsdl2-image-dev libflac-dev libmpg123-dev libpng-dev libmpeg2-4-dev

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
echo "Compile Amiberry $branch $tag with make arguments '$MAKEARGS'..."
sleep 1
make clean
make $MAKEARGS
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


# show default amiga emulator dialog
dialog --clear --stdout \
--title "Default Amiga emulator" \
--yesno "Do you want to use Amiberry as default Amiga emulator?" 0 0

# exit, if no is selected
if [ $? -ne 0 ]; then
  exit
fi

AMIGA_EMULATOR="amiberry"

# add or update amiga emulator in config, if it doesn't exist
if [ "$(grep -i "AMIGA_EMULATOR=" ~/.hstwb-installer/config.sh)" == "" ]; then
        echo "export AMIGA_EMULATOR=\"$AMIGA_EMULATOR\"" >>~/.hstwb-installer/config.sh
else
        sed -e "s/^\(export AMIGA_EMULATOR=\).*/\1\"$(echo "$AMIGA_EMULATOR" | sed -e "s/\//\\\\\//g")\"/g" ~/.hstwb-installer/config.sh >~/.hstwb-installer/_config.sh
        mv -f ~/.hstwb-installer/_config.sh ~/.hstwb-installer/config.sh
fi

# add execute permission to config
chmod +x ~/.hstwb-installer/config.sh
