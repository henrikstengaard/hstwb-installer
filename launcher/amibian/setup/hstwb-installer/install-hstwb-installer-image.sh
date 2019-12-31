#!/bin/bash

# Install HstWB Installer Image
# -----------------------------
# Author: Henrik Noefjand Stengaard
# Date: 2019-12-31
#
# Bash script to download and install latest HstWB Installer UAE4ARM image.

# paths
UAE4ARMPATH=~/.hstwb-installer/uae4arm
AMIGAHDDPATH="/root/amibian/amiga_files/hdd/hstwb"

function is_online()
{
	# ping hstwb website to check if system has internet connection
	ping -c1 hstwb.firstrealize.com &>/dev/null

	# return error, if internet is offline
	if [ $? -ne 0 ]; then
		# show offline dialog
		dialog --clear --title "Install HstWB Installer image" --msgbox "The internet connection appears to be offline. A menu will now be shown with options to retry or change WiFi configuration." 0 0

		return 1
	fi

	return 0
}

function latest_image()
{
	clear

	# get hstwb installer uae4arm latest
	echo "Downloading latest HstWB Installer UAE4ARM image url..."
	echo ""
	wget https://hstwb.firstrealize.com/downloads/uae4arm_latest.txt --no-check-certificate -O /tmp/uae4arm_latest.txt

	# fail, if wget returned error
	if [ $? -ne 0 ]; then
		# show error dialog
		dialog --title "Install HstWB Installer image" --msgbox "Failed to get latest HstWB Installer UAE4ARM image link!" 0 0
		return 1
	fi

	# get uae4arm latest url and filename
	UAE4ARMLATESTURL="$(cat /tmp/uae4arm_latest.txt)"
	UAE4ARMLATESTFILENAME="$(basename "$UAE4ARMLATESTURL")"

	# delete uae4arm latest
	rm /tmp/uae4arm_latest.txt

	return 0
}

function download_image()
{
	clear

	# create uae4arm path, if it doesn't exist
	if [ ! -d "$UAE4ARMPATH" ]; then
		mkdir -p "$UAE4ARMPATH"
	fi

	# download latest hstwb installer uae4arm image, if it doesn't exist
	if [ -f "$UAE4ARMPATH/$UAE4ARMLATESTFILENAME" ]; then
		# show confirm dialog
		dialog --clear --stdout \
		--title "Install HstWB Installer image" \
		--yesno "Latest HstWB Installer UAE4ARM image '$UAE4ARMLATESTFILENAME' is already downloaded. Do you want to download this HstWB Installer UAE4ARM image again?" 0 0

		# return true, if no is selected
		if [ $? -ne 0 ]; then
			return 0
		fi

		# delete existing latest hstwb installer image
		rm "$UAE4ARMPATH/$UAE4ARMLATESTFILENAME"
	fi

	echo "Downloading '$UAE4ARMLATESTURL' to '$UAE4ARMPATH'..."
	echo ""

	# download latest hstwb installer uae4arm image
	wget "$UAE4ARMLATESTURL" --no-check-certificate -P "$UAE4ARMPATH"

	# fail, if wget returned error
	if [ $? -ne 0 ]; then
		# show error dialog
		dialog --title "Install HstWB Installer image" --msgbox "Failed to download HstWB Installer UAE4ARM image!" 0 0
		return 1
	fi

	return 0
}

function unzip_image()
{
	clear

	# create amiga hdd path, if it doesn't exist
	if [ ! -d "$AMIGAHDDPATH" ]; then
		mkdir -p "$AMIGAHDDPATH" >/dev/null
	fi

	# unzip latest hstwb installer uae4arm image to amibian hdd path
	echo "Unzipping '$UAE4ARMLATESTFILENAME' to '$AMIGAHDDPATH'..."
	sleep 1
	unzip -o "$UAE4ARMPATH/$UAE4ARMLATESTFILENAME" -d "$AMIGAHDDPATH"

	# return false, if unzip failed
	if [ $? -ge 2 ]; then
		# show error dialog
		dialog --title "Install HstWB Installer image" --msgbox "Failed to unzip HstWB Installer UAE4ARM image!" 0 0
		return 1
	fi

	return 0
}

function retry_menu()
{
	while true; do
		choices=$(dialog --clear --stdout \
		--title "Install HstWB Installer image" \
		--menu "Select option:" 0 0 0 \
		1 "Retry install HstWB Installer image" \
		2 "Change WiFi configuration" \
		3 "Exit")

		clear

		# exit, if cancelled
		if [ $? -ne 0 ]; then
			exit
		fi

		for choice in $choices; do
			case $choice in
			1)
				return 0
				;;
			2)
				$HSTWBINSTALLERROOT/launcher/amibian/setup/amibian/change-wifi-configuration.sh
				;;
			3)
				exit
				;;
			esac
		done
	done

	return 0
}

# show confirm dialog
dialog --clear --stdout \
--title "Install HstWB Installer image" \
--yesno "Do you want to download and install latest HstWB Installer UAE4ARM image? WARNING: Any existing image files in Amiga hdd directory \"$AMIGAHDDPATH\" will be overwritten!" 0 0

# exit, if no is selected
if [ $? -ne 0 ]; then
  exit
fi

while true;do
	if is_online && latest_image && download_image && unzip_image; then
		# show success dialog
		dialog --clear --title "Success" --msgbox "Successfully installed latest HstWB Installer UAE4ARM image in Amiga hdd directory \"$AMIGAHDDPATH\"." 0 0

		exit
	else
		retry_menu
	fi
done
