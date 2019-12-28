#!/bin/bash

# Install HstWB Installer Image
# -----------------------------
# Author: Henrik Noefjand Stengaard
# Date: 2019-12-28
#
# Bash script to download and install latest HstWB Installer UAE4ARM image.

# paths
UAE4ARMPATH=~/.hstwb-installer/uae4arm
AMIBIANHDDPATH="/root/amibian/amiga_files/hdd"

# fail, if amibian hdd path doesn't exist
if [ ! -d "$AMIBIANHDDPATH" ]; then
	echo "ERROR: Amibian hdd path \"$AMIBIANHDDPATH\" doesn't exist"
	exit 1
fi

# get hstwb installer uae4arm latest
echo "Downloading latest HstWB Installer UAE4ARM image url"
echo ""
wget https://hstwb.firstrealize.com/downloads/uae4arm_latest.txt -O /tmp/uae4arm_latest.txt

# fail, if wget returned error
if [ $? -ne 0 ]; then
  exit 1
fi

# get uae4arm latest url and filename
UAE4ARMLATESTURL="$(cat /tmp/uae4arm_latest.txt)"
UAE4ARMLATESTFILENAME="$(basename "$UAE4ARMLATESTURL")"

# delete uae4arm latest
rm /tmp/uae4arm_latest.txt

# show confirm dialog
dialog --clear --stdout \
--title "Install HstWB Installer image" \
--yesno "Latest HstWB Installer UAE4ARM image is \"$UAE4ARMLATESTFILENAME\". Do you want to download and install this HstWB Installer UAE4ARM image? WARNING: Any existing image files in Amibian hdd directory \"$AMIBIANHDDPATH\" will be overwritten!" 0 0

# exit, if no is selected
if [ $? -ne 0 ]; then
  exit
fi

# create uae4arm path, if it doesn't exist
if [ ! -d "$UAE4ARMPATH" ]; then
	mkdir -p "$UAE4ARMPATH"
fi

# download latest hstwb installer uae4arm image, if it doesn't exist
if [ ! -f "$UAE4ARMPATH/$UAE4ARMLATESTFILENAME" ]; then
	echo "Downloading $UAE4ARMLATESTURL to $UAE4ARMPATH"
	echo ""

	# download latest hstwb installer uae4arm image
	wget "$UAE4ARMLATESTURL" --no-check-certificate -P "$UAE4ARMPATH"

	# fail, if wget returned error
	if [ $? -ne 0 ]; then
		exit 1
	fi
else
	echo "Using $UAE4ARMLATESTFILENAME in $UAE4ARMPATH"
	echo ""
fi

# unzip latest hstwb installer uae4arm image to amibian hdd path
echo "Unzipping $UAE4ARMLATESTFILENAME to $AMIBIANHDDPATH"
echo ""
sleep 1
unzip -o "$UAE4ARMPATH/$UAE4ARMLATESTFILENAME" -d "$AMIBIANHDDPATH"

# show success dialog
dialog --clear --title "Success" --msgbox "Successfully installed latest HstWB Installer UAE4ARM image in Amibian hdd directory \"$AMIBIANHDDPATH\"." 0 0
