#!/bin/bash -e

# Install Kickstart Rom
# ---------------------
# Author: Henrik Noerfjand Stengaard
# Date: 2022-02-10
#
# A bash script for HstWB Installer to find and install A1200 Kickstart 3.2.1, 3.2, 3.1.4 or 3.1 rom file in install directory and install it in kickstarts directory.

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

# find hstwb self install
$HSTWB_INSTALLER_ROOT/launcher/raspberry-pi/setup/hstwb-installer/find-hstwb-self-install.sh --quiet

# show error dialog, if install directory doesn't exist
if [ ! -d "$installdir" ]; then
        dialog --clear --title "ERROR" --msgbox "Install directory '$installdir' doesn't exist." 0 0
        return 1
fi

function detect_kick321()
{
	romfile=$1
	md5=$2

        # get kickstart rom filename
        romfilename=$(basename "$romfile")

	# add rom file, if md5 matches kickstart 3.2.1 47.102 a1200 rom, hyperion entertainment
	if [ "$md5" == "1c76a282cfca1565ad0d46089742ef20" ]; then
		echo "$romfile" >>/tmp/_kickstartfiles.txt
		echo "$romfilename (Kickstart 3.2.1 47.102 A1200 rom)" >>/tmp/_kickstartnames.txt
		return 0
	fi

	return 1
}

function detect_kick32()
{
        romfile=$1
        md5=$2

        # get kickstart rom filename
        romfilename=$(basename "$romfile")

        # add rom file, if md5 matches kickstart 3.2 47.96 a1200 rom, hyperion entertainment
        if [ "$md5" == "cad62a102848e13bf04d8a3b0f8be6ab" ]; then
                echo "$romfile" >>/tmp/_kickstartfiles.txt
                echo "$romfilename (Kickstart 3.2 47.96 A1200 rom)" >>/tmp/_kickstartnames.txt
		return 0
        fi

	return 1
}

function detect_kick314()
{
        romfile=$1
        md5=$2

	# get kickstart rom filename
	romfilename=$(basename "$romfile")

        # add rom file, if md5 matches kickstart 3.1.4 46.143 a1200 rom, hyperion entertainment
	if [ "$md5" == "6de08cd5c5efd926d0a7643e8fb776fe" ]; then
		echo "$romfile" >>/tmp/_kickstartfiles.txt
		echo "$romfilename (Kickstart 3.1.4 46.143 A1200 rom)" >>/tmp/_kickstartnames.txt
                return 0
	fi

        # add rom file, if md5 matches kickstart 3.1.4 46.143 a1200 rom, hyperion entertainment
        if [ "$md5" == "79bfe8876cd5abe397c50f60ea4306b9" ]; then
                echo "$romfile" >>/tmp/_kickstartfiles.txt
                echo "$romfilename (Kickstart 3.1.4 46.143 A1200 rom)" >>/tmp/_kickstartnames.txt
                return 0
        fi

	return 1
}

function detect_kick31()
{
        romfile=$1
        md5=$2

        # get kickstart rom filename
        romfilename=$(basename "$romfile")

        # add rom file, if md5 matches kickstart 3.1 40.068 a1200 rom, cloanto amiga forever 8
        if [ "$md5" == "43efffafb382528355bb4cdde9fa9ce7" ]; then
                echo "$romfile" >>/tmp/_kickstartfiles.txt
                echo "$romfilename (Kickstart 3.1 40.068 A1200 rom)" >>/tmp/_kickstartnames.txt
                return 0
        fi

        # add rom file, if md5 matches kickstart 3.1 40.068 a1200 rom, cloanto amiga forever 7/2016
        if [ "$md5" == "dc3f5e4698936da34186d596c53681ab" ]; then
                echo "$romfile" >>/tmp/_kickstartfiles.txt
                echo "$romfilename (Kickstart 3.1 40.068 A1200 rom)" >>/tmp/_kickstartnames.txt
                return 0
        fi

        # add rom file, if md5 matches kickstart 3.1 40.068 a1200 rom, original
        if [ "$md5" == "646773759326fbac3b2311fd8c8793ee" ]; then
                echo "$romfile" >>/tmp/_kickstartfiles.txt
                echo "$romfilename (Kickstart 3.1 40.068 A1200 rom)" >>/tmp/_kickstartnames.txt
                return 0
        fi

	return 1
}



# install a1200 kickstart rom 3.2.1, 3.2, 3.1.4 or 3.1
function install()
{
	echo -n "" >/tmp/_kickstartfiles.txt
	echo -n "" >/tmp/_kickstartnames.txt

        # find any kickstart rom files in install directory
        while read romfile; do
                # get md5 from rom file
                md5=$(md5sum "$romfile" | awk '{ print $1 }')


		# install kickstart 3.2.1, if detected
	        if detect_kick321 "$romfile" "$md5"; then
			kickstartfile=$(sed -n '1p' /tmp/_kickstartfiles.txt)
			kickstartname=$(sed -n '1p' /tmp/_kickstartnames.txt)

	                rm /tmp/_kickstartfiles.txt
	                rm /tmp/_kickstartnames.txt

		        # copy rom file to kickstarts directory
	        	cp "$kickstartfile" "$kickstartsdir/kick31.rom"
			cp "$kickstartfile" "$kickstartsdir/kick321.rom"

		        # show success dialog
	        	dialog --clear --title "Success" --msgbox "Successfully installed Kickstart rom '$kickstartname' in kickstarts directory '$kickstartsdir'" 0 0

	                return 0
	        fi
        done < <(find "$installdir" -type f -name '*.rom')

        echo -n "" >/tmp/_kickstartfiles.txt
        echo -n "" >/tmp/_kickstartnames.txt

        # find any kickstart rom files in install directory
        while read romfile; do
                # get md5 from rom file
                md5=$(md5sum "$romfile" | awk '{ print $1 }')


	        # install kickstart 3.2, if detected
        	if detect_kick32 "$romfile" "$md5"; then
                	kickstartfile=$(sed -n '1p' /tmp/_kickstartfiles.txt)
	                kickstartname=$(sed -n '1p' /tmp/_kickstartnames.txt)

	                rm /tmp/_kickstartfiles.txt
	                rm /tmp/_kickstartnames.txt

	                # copy rom file to kickstarts directory
	                cp "$kickstartfile" "$kickstartsdir/kick31.rom"
			cp "$kickstartfile" "$kickstartsdir/kick32.rom"

	                # show success dialog
	                dialog --clear --title "Success" --msgbox "Successfully installed Kickstart rom '$kickstartname' in kickstarts directory '$kickstartsdir'" 0 0

	                return 0
	        fi
        done < <(find "$installdir" -type f -name '*.rom')

        # find any kickstart rom files in install directory
        while read romfile; do
                # get md5 from rom file
                md5=$(md5sum "$romfile" | awk '{ print $1 }')

	        # install kickstart 3.1.4, if detected
	        if detect_kick314 "$romfile" "$md5"; then
        	        kickstartfile=$(sed -n '1p' /tmp/_kickstartfiles.txt)
	                kickstartname=$(sed -n '1p' /tmp/_kickstartnames.txt)

	                rm /tmp/_kickstartfiles.txt
	                rm /tmp/_kickstartnames.txt

	                # copy rom file to kickstarts directory
	                cp "$kickstartfile" "$kickstartsdir/kick31.rom"
			cp "$kickstartfile" "$kickstartsdir/kick314.rom"

	                # show success dialog
	                dialog --clear --title "Success" --msgbox "Successfully installed Kickstart rom '$kickstartname' in kickstarts directory '$kickstartsdir'" 0 0

	                return 0
	        fi
        done < <(find "$installdir" -type f -name '*.rom')

        # find any kickstart rom files in install directory
        while read romfile; do
                # get md5 from rom file
                md5=$(md5sum "$romfile" | awk '{ print $1 }')

	        # install kickstart 3.1, if detected
	        if detect_kick31 "$romfile" "$md5"; then
	                kickstartfile=$(sed -n '1p' /tmp/_kickstartfiles.txt)
	                kickstartname=$(sed -n '1p' /tmp/_kickstartnames.txt)

	                rm /tmp/_kickstartfiles.txt
	                rm /tmp/_kickstartnames.txt

	                # copy rom file to kickstarts directory
	                cp "$kickstartfile" "$kickstartsdir/kick31.rom"

		        # get rom key file
		        romdir=$(dirname "$romfile")
		        romkeyfile="$romdir/rom.key"

		        # copy rom key, if rom key exists in directory with kickstart rom
		        romkeytext=""
		        if [ -f "$romkeyfile"]; then
		                romkeytext=" and rom key"
	        	        cp "$romkeyfile" "$kickstartsdir/rom.key"
		        fi

	                # show success dialog
	                dialog --clear --title "Success" --msgbox "Successfully installed Kickstart rom '$kickstartname'$romkeytext in kickstarts directory '$kickstartsdir'" 0 0

	                return 0
	        fi
        done < <(find "$installdir" -type f -name '*.rom')

        echo -n "" >/tmp/_kickstartfiles.txt
        echo -n "" >/tmp/_kickstartnames.txt

	# find any kickstart rom files in install directory
	while read romfile; do
		# get md5 from rom file
		md5=$(md5sum "$romfile" | awk '{ print $1 }')

	        # get kickstart rom filename
        	romfilename=$(basename "$romfile")

		echo "$romfile" >>/tmp/_kickstartfiles.txt
		echo "$romfilename (Unknown Kickstart rom)" >>/tmp/_kickstartnames.txt
	done < <(find "$installdir" -type f -name '*.rom')


        # build options
        options=()
        n=0
        while read line ; do
                n=$(($n + 1))
                options+=($n "$line")
        done </tmp/_kickstartnames.txt

        # fail, if  kickstart rom is not installed
        if [ $n = 0 ]; then
	        rm /tmp/_kickstartfiles.txt
	        rm /tmp/_kickstartnames.txt

                # show success dialog
                dialog --clear --title "ERROR" --msgbox "A1200 Kickstart 3.2.1, 3.2, 3.1.4 or 3.1 rom doesn't exist in install directory '$installdir'" 0 0
                return 1
        fi

        # show select kickstart rom
        choice=$(dialog --clear --stdout --title "Select A1200 Kickstart rom" --menu "Select A1200 Kickstart rom to install:" 0 0 0 "${options[@]}")

        # exit, if cancelled
        if [ -z "$choice" ]; then
                rm /tmp/_kickstartfiles.txt
                rm /tmp/_kickstartnames.txt

                return 1
        fi

	# get selected kickstart rom
	kickstartfile=$(sed "${choice[@]}!d" /tmp/_kickstartfiles.txt)

        rm /tmp/_kickstartfiles.txt
	rm /tmp/_kickstartnames.txt

	# copy rom file to kickstarts directory
	cp "$kickstartfile" "$kickstartsdir/kick31.rom"


	# get rom key file
	romdir=$(dirname "$kickstartfile")
	romkeyfile="$romdir/rom.key"

	# copy rom key, if rom key exists in directory with kickstart rom
	romkeytext=""
	if [ -f "$romkeyfile"]; then
		romkeytext=" and rom key"
		cp "$romkeyfile" "$kickstartsdir/rom.key"
	fi

	# get kickstart rom filename
	romfilename=$(basename "$KICKSTART_ROM")

	# show success dialog
	dialog --clear --title "Success" --msgbox "Successfully installed Kickstart rom '$romfilename'$romkeytext in kickstarts directory '$kickstartsdir'" 0 0
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
	choices=$(dialog --clear --stdout --title "Install Kickstart" --menu "Find and install A1200 Kickstart 3.2.1, 3.2, 3.1.4 or 3.1 rom from install directory '$installdir':" 0 0 0 1 "Install Kickstart rom" 2 "Change Install Directory" 3 "Exit")

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
