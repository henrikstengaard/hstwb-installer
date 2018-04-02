#!/bin/bash

# Install Kickstart
# -----------------
# Author: Henrik Noerfjand Stengaard
# Date: 2018-04-02
#
# A bash script to find and install A1200 Kickstart 3.1 (40.068) rom file in install directory and install it in kickstarts directory.


# install a1200 kickstart 3.1 rom
function install()
{
	# show error dialog, if install directory doesn't exist
	if [ ! -d "$installdir" ]; then
		dialog --clear --title "ERROR" --msgbox "Install directory '$installdir' doesn't exist." 0 0
		return 1
	fi

	clear
	echo "Finding A1200 Kickstart 3.1 (40.068) rom in install directory '$installdir'..."

	# find a1200 kickstart 3.1 rom files in install directory
	find "$installdir" -type f | while read romfile; do
		echo "$romfile"

		# get md5 from rom file
		md5=$(md5sum "$romfile" | awk '{ print $1 }')

		# copy rom file, if md5 matches cloanto amiga forever kickstart 3.1 (40.068) (a1200) rom
		if [ "$md5" == "dc3f5e4698936da34186d596c53681ab" ]; then
			# get rom key file
			romdir=$(dirname "$romfile")
			romkeyfile="$romdir/rom.key"

			# show error dialog, if cloanto amiga forever kickstart key file doesn't exist
			if [ ! -f "$romkeyfile" ]; then
				dialog --clear --title "ERROR" --msgbox "Cloanto Amiga Forever Kickstart key file 'rom.key' doesn't exist in install directory '$installdir'." 0 0
				return 1
			fi

			cp "$romfile" "$kickstartsdir/kick31.rom"
			cp "$romkeyfile" "$kickstartsdir/rom.key"

			# show success dialog
			dialog --clear --title "Success" --msgbox "Successfully installed Cloanto Amiga Forever Kickstart 3.1 (40.068) rom in kickstarts directory '$kickstartsdir'" 0 0

			return 0
		fi

		# copy rom file, if md5 matches original kickstart 3.1 (40.068) (a1200) rom
		if [ "$md5" == "646773759326fbac3b2311fd8c8793ee" ]; then
			cp "$romfile" "$kickstartsdir/kick31.rom"

			# show success dialog
			dialog --clear --title "Success" --msgbox "Successfully installed Original Kickstart 3.1 (40.068) rom in kickstarts directory '$kickstartsdir'" 0 0

			return 0
		fi
	done

	echo "Done."

	# show success dialog
	dialog --clear --title "ERROR" --msgbox "A1200 Kickstart 3.1 (40.068) rom doesn't exist in install directory '$installdir'" 0 0

	return 1
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


# kickstarts directory
kickstartsdir="/root/amibian/amiga_files/kickstarts"

# install directory
installdir="/media/usb0/kickstart"

# install
install=1


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


# exit, if kick31.rom already exists
if [ -f "$kickstartsdir/kick31.rom" ]; then
	exit
fi

# exit, if install argument is present and install is successful
if [ $install == 0 ] && install; then
	exit
fi

# install kickstart menu
while true; do
	# show install kickstart menu
	choices=$(dialog --clear --stdout --title "Install Kickstart" --menu "Find and install A1200 Kickstart 3.1 (40.068) rom from install directory '$installdir':" 0 0 0 1 "Install Kickstart rom" 2 "Change Install Directory")

	# exit, if cancelled
	if [ $? -ne 0 ]; then
		clear
		exit
	fi

	# choices
    for choice in $choices; do
        case $choice in
        1)
			install
			;;
        2)
			change_install_directory
			;;
		esac
		clear
	done
done