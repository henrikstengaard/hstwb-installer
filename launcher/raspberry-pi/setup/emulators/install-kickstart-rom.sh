#!/bin/bash

# Install Kickstart Rom
# ---------------------
# Author: Henrik Noerfjand Stengaard
# Date: 2020-12-18
#
# A bash script for HstWB Installer to find and install A1200 Kickstart 3.1.4 or 3.1 rom file in install directory and install it in kickstarts directory.

# fail, if amiga kickstarts path is not set
if [ -z "$AMIGA_KICKSTARTS_PATH" ]; then
	dialog --clear --title "ERROR" --msgbox "ERROR: Amiga Kickstarts path 'AMIGA_KICKSTARTS_PATH' is not set!" 0 0
	exit 1
fi

# create amiga kickstarts path, if it doesn't exist
if [ ! -d "$AMIGA_KICKSTARTS_PATH" ]; then
	mkdir -p "$AMIGA_KICKSTARTS_PATH"
fi

# paths
kickstartsdir=$AMIGA_KICKSTARTS_PATH
installdir="/media/hstwb-self-install/kickstart"

# install
install=1

# find hstwb self install
$HSTWB_INSTALLER_ROOT/launcher/raspberry-pi-os/setup/hstwb-installer/find-hstwb-self-install.sh

# install a1200 kickstart 3.1 rom
function install()
{
	# show error dialog, if install directory doesn't exist
	if [ ! -d "$installdir" ]; then
		dialog --clear --title "ERROR" --msgbox "Install directory '$installdir' doesn't exist." 0 0
		return 1
	fi

	# set installed false
	installed=1

	# find a1200 kickstart 3.1 rom files in install directory
	while read romfile; do
		# get md5 from rom file
		md5=$(md5sum "$romfile" | awk '{ print $1 }')

		# copy rom file, if md5 matches kickstart 3.1.4 46.143 a1200 rom, hyperion entertainment
		if [ "$md5" == "79bfe8876cd5abe397c50f60ea4306b9" ]; then
			# copy rom and key file to kickstarts directory
			cp "$romfile" "$kickstartsdir/kick31.rom"

			# set installed true
			installed=0

			# show success dialog
			dialog --clear --title "Success" --msgbox "Successfully installed Kickstart 3.1.4 46.143 A1200 rom, Hyperion Entertainment in kickstarts directory '$kickstartsdir'" 0 0
			break
		fi

		# copy rom file, if md5 matches kickstart 3.1 40.068 a1200 rom, cloanto amiga forever 8
		if [ "$md5" == "43efffafb382528355bb4cdde9fa9ce7" ]; then
			# get rom key file
			romdir=$(dirname "$romfile")
			romkeyfile="$romdir/rom.key"

			# show error dialog, if cloanto amiga forever kickstart key file doesn't exist
			if [ ! -f "$romkeyfile" ]; then
				dialog --clear --title "ERROR" --msgbox "Cloanto Amiga Forever Kickstart key file 'rom.key' doesn't exist in install directory '$installdir'." 0 0
				break
			fi

			# copy rom and key file to kickstarts directory
			cp "$romfile" "$kickstartsdir/kick31.rom"
			cp "$romkeyfile" "$kickstartsdir/rom.key"

			# set installed true
			installed=0

			# show success dialog
			dialog --clear --title "Success" --msgbox "Successfully installed Kickstart 3.1 40.068 A1200 rom, Cloanto Amiga Forever 8 in kickstarts directory '$kickstartsdir'" 0 0
			break
		fi

		# copy rom file, if md5 matches kickstart 3.1 40.068 a1200 rom, cloanto amiga forever 7/2016
		if [ "$md5" == "dc3f5e4698936da34186d596c53681ab" ]; then
			# get rom key file
			romdir=$(dirname "$romfile")
			romkeyfile="$romdir/rom.key"

			# show error dialog, if cloanto amiga forever kickstart key file doesn't exist
			if [ ! -f "$romkeyfile" ]; then
				dialog --clear --title "ERROR" --msgbox "Cloanto Amiga Forever Kickstart key file 'rom.key' doesn't exist in install directory '$installdir'." 0 0
				break
			fi

			# copy rom and key file to kickstarts directory
			cp "$romfile" "$kickstartsdir/kick31.rom"
			cp "$romkeyfile" "$kickstartsdir/rom.key"

			# set installed true
			installed=0

			# show success dialog
			dialog --clear --title "Success" --msgbox "Successfully installed Kickstart 3.1 40.068 A1200 rom, Cloanto Amiga Forever 7/2016 in kickstarts directory '$kickstartsdir'" 0 0
			break
		fi

		# copy rom file, if md5 matches kickstart 3.1 40.068 a1200 rom, original
		if [ "$md5" == "646773759326fbac3b2311fd8c8793ee" ]; then
			# copy rom file to kickstarts directory
			cp "$romfile" "$kickstartsdir/kick31.rom"

			# set installed true
			installed=0

			# show success dialog
			dialog --clear --title "Success" --msgbox "Successfully installed Kickstart 3.1 40.068 A1200 rom, Original in kickstarts directory '$kickstartsdir'" 0 0
			break
		fi
	done < <(find "$installdir" -type f)

	# show error dialog, if kickstart rom is not installed
	if [ $installed != 0 ]; then
		# show success dialog
		dialog --clear --title "ERROR" --msgbox "A1200 Kickstart 3.1.4 or 3.1 rom doesn't exist in install directory '$installdir'" 0 0
		return 1
	fi

	return 0
}


# change install directory
function change_install_directory()
{
	# show select install directory dialog
	newinstalldir=$(dialog --clear --stdout --title "Select install directory" --dselect "$installdir" 0 0)

	# return, if cancelled
	if [ $? -ne 0 ]; then
		return 1
	fi

	# set install dir
	installdir="$newinstalldir"

	return 0
}


# parse arguments
for i in "$@"
do
case $i in
    -i|--install)
    install=0
    shift
    ;;
    -id=*|--installdir=*)
    installdir="${i#*=}"
    shift
    ;;
    -kd=*|--kickstartsdir=*)
    kickstartsdir="${i#*=}"
    shift
    ;;
    *)
        # unknown argument
    ;;
esac
done

# install, if install argument is present
if [ $install == 0 ]; then
	# exit, if install is successful
	if install; then
		exit
	fi
fi

# install kickstart menu
while true; do
	# show install kickstart menu
	choices=$(dialog --clear --stdout --title "Install Kickstart" --menu "Find and install A1200 Kickstart 3.1.4 or 3.1 rom from install directory '$installdir':" 0 0 0 1 "Install Kickstart rom" 2 "Change Install Directory" 3 "Exit")

	# exit, if cancelled
	if [ -z $choices ]; then
		clear
		exit
	fi

	# choices
    for choice in $choices; do
        case $choice in
        1)
			# exit, if install is successful
			if install; then
				exit
			fi
			;;
        2)
			change_install_directory
			;;
        3)
			exit
			;;
		esac
		clear
	done
done
