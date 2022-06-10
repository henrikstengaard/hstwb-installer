#!/bin/bash

# Install HstWB Installer Image
# -----------------------------
# Author: Henrik Noefjand Stengaard
# Date: 2022-01-04
#
# Bash script to download and install latest HstWB Installer UAE4ARM image.

# fail, if amiga hdd path doesn't exist
if [ ! -d "$AMIGA_HDD_PATH" ]; then
	mkdir -p "$AMIGA_HDD_PATH"
        #echo "ERROR: Amiga HDD path \"$AMIGA_HDD_PATH\" doesn't exist!"
	#exit 1
fi

# paths
HSTWB_HDD_PATH="$AMIGA_HDD_PATH/hstwb"
UAE4ARM_IMAGE_PATH=~/.hstwb-installer/uae4arm-image

function is_online()
{
	# ping hstwb website to check if system has internet connection
	ping -c1 hstwb.firstrealize.com &>/dev/null

	# return error, if internet is offline
	if [ $? -ne 0 ]; then
		# show offline dialog
		dialog --clear --title "Install HstWB Installer image" --msgbox "The internet connection appears to be offline." 0 0

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
	UAE4ARM_LATEST_URL="$(cat /tmp/uae4arm_latest.txt)"
	UAE4ARM_LATEST_FILENAME="$(basename "$UAE4ARM_LATEST_URL")"

	# delete uae4arm latest
	rm /tmp/uae4arm_latest.txt

	return 0
}

function download_image()
{
	clear

	# create uae4arm path, if it doesn't exist
	if [ ! -d "$UAE4ARM_IMAGE_PATH" ]; then
		mkdir -p "$UAE4ARM_IMAGE_PATH"
	fi

	# download latest hstwb installer uae4arm image, if it doesn't exist
	if [ -f "$UAE4ARM_IMAGE_PATH/$UAE4ARM_LATEST_FILENAME" ]; then
		# show confirm dialog
		dialog --clear --stdout \
		--title "Install HstWB Installer image" \
		--yesno "Latest HstWB Installer UAE4ARM image '$UAE4ARM_LATEST_FILENAME' is already downloaded. Do you want to download this HstWB Installer UAE4ARM image again?" 0 0

		# return true, if no is selected
		if [ $? -ne 0 ]; then
			return 0
		fi

		# delete existing latest hstwb installer image
		rm "$UAE4ARM_IMAGE_PATH/$UAE4ARM_LATEST_FILENAME"
	fi

	echo "Downloading '$UAE4ARM_LATEST_URL' to '$UAE4ARM_IMAGE_PATH'..."
	echo ""

	# download latest hstwb installer uae4arm image
	wget "$UAE4ARM_LATEST_URL" --no-check-certificate -P "$UAE4ARM_IMAGE_PATH"

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

	# create hstwb hdd path, if it doesn't exist
	if [ ! -d "$HSTWB_HDD_PATH" ]; then
		mkdir -p "$HSTWB_HDD_PATH" >/dev/null
	fi

	# create start first path, if it doesn't exist
        #if [ ! -d "$HSTWB_HDD_PATH/start-first" ]; then
        #        mkdir -p "$HSTWB_HDD_PATH/start-first" >/dev/null
        #fi

	# copy start first to hstwb hdd path#
	#cp -R "$HSTWB_INSTALLER_ROOT/emulators/amiberry/start-first/." "$HSTWB_HDD_PATH/start-first"

	# unzip latest hstwb installer uae4arm image to hstwb hdd path
	echo "Unzipping '$UAE4ARM_LATEST_FILENAME' to '$HSTWB_HDD_PATH'..."
	sleep 1
	unzip -o "$UAE4ARM_IMAGE_PATH/$UAE4ARM_LATEST_FILENAME" -d "$HSTWB_HDD_PATH"

	# return false, if unzip failed
	if [ $? -ge 2 ]; then
		# show error dialog
		dialog --title "Install HstWB Installer image" --msgbox "Failed to unzip HstWB Installer UAE4ARM image!" 0 0
		return 1
	fi

	return 0
}

function update_configs()
{
	# amiberry config
	if [ ! "$AMIBERRY_CONF_PATH" == "" ]; then
		# create amiberry config directory, if it doesn't exist
		if [ ! -d "$AMIBERRY_CONF_PATH" ]; then
			mkdir -p "$AMIBERRY_CONF_PATH" >/dev/null
		fi

		# copy amiberry configs
		cp -R "$HSTWB_INSTALLER_ROOT/emulators/amiberry/configs/." "$AMIBERRY_CONF_PATH"

		# replace amiga hdd and kickstarts path placeholders
		find "$AMIBERRY_CONF_PATH" -name "hstwb-*.uae" -type f -exec sed -i "s/\\$\\[AMIGA_HDD_PATH\\]/$(echo "$HSTWB_HDD_PATH" | sed -e "s/\//\\\\\//g")/g" {} \;
		find "$AMIBERRY_CONF_PATH" -name "hstwb-*.uae" -type f -exec sed -i "s/\\$\\[AMIGA_KICKSTARTS_PATH\\]/$(echo "$AMIGA_KICKSTARTS_PATH" | sed -e "s/\//\\\\\//g")/g" {} \;
	fi

	# uae4arm config
	if [ ! "$UAE4ARM_CONF_PATH" == "" ]; then
		# create uae4arm config directory, if it doesn't exist
		if [ ! -d "$UAE4ARM_CONF_PATH" ]; then
			mkdir -p "$UAE4ARM_CONF_PATH" >/dev/null
		fi

		# copy chips uae4arm configs
		cp -R "$HSTWB_INSTALLER_ROOT/emulators/chips_uae4arm/configs/." "$UAE4ARM_CONF_PATH"

		# replace amiga hdd and kickstarts path placeholders
		find "$UAE4ARM_CONF_PATH" -name "hstwb-*.uae" -type f -exec sed -i "s/\\$\\[AMIGA_HDD_PATH\\]/$(echo "$HSTWB_HDD_PATH" | sed -e "s/\//\\\\\//g")/g" {} \;
		find "$UAE4ARM_CONF_PATH" -name "hstwb-*.uae" -type f -exec sed -i "s/\\$\\[AMIGA_KICKSTARTS_PATH\\]/$(echo "$AMIGA_KICKSTARTS_PATH" | sed -e "s/\//\\\\\//g")/g" {} \;
	fi

        # fs-uae config
        if [ ! "$FSUAE_CONF_PATH" == "" ]; then
                # create fs-uae config directory, if it doesn't exist
                if [ ! -d "$FSUAE_CONF_PATH" ]; then
                        mkdir -p "$FSUAE_CONF_PATH" >/dev/null
                fi

                # copy fs-uae configs
                cp -R "$HSTWB_INSTALLER_ROOT/emulators/fs-uae/configs/rpi/." "$FSUAE_CONF_PATH"

                # replace amiga hdd and kickstarts path placeholders
                find "$FSUAE_CONF_PATH" -name "hstwb-*.fs-uae" -type f -exec sed -i "s/\\$\\[AMIGA_HDD_PATH\\]/$(echo "$HSTWB_HDD_PATH" | sed -e "s/\//\\\\\//g")/g" {} \;
                find "$FSUAE_CONF_PATH" -name "hstwb-*.fs-uae" -type f -exec sed -i "s/\\$\\[AMIGA_KICKSTARTS_PATH\\]/$(echo "$AMIGA_KICKSTARTS_PATH" | sed -e "s/\//\\\\\//g")/g" {} \;
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
				$HSTWB_INSTALLER_ROOT/launcher/amibian/setup/amibian/change-wifi-configuration.sh
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
--yesno "This will download and install latest HstWB Installer UAE4ARM image and requires approx. 2.5GB free diskspace.\n\nWARNING: Any existing HstWB Installer image files in Amiga hdd directory \"$AMIGA_HDD_PATH\" and HstWB Installer configuration files will be overwritten!\n\nDo you want to download and install latest HstWB Installer UAE4ARM image?" 0 0

# exit, if no is selected
if [ $? -ne 0 ]; then
  exit
fi

while true;do
	if is_online && latest_image && download_image && unzip_image && update_configs; then
		# show success dialog
		# Amiberry requires first start of \"hstwb-build-must-start-first-jit.uae\" configuration file before starting to build the HstWB Installer image (not required for UAE4ARM).\n\n
		dialog --clear --title "Success" --msgbox "Successfully installed latest HstWB Installer UAE4ARM image in Amiga hdd directory \"$AMIGA_HDD_PATH\".\n\nTo start building HstWB Installer image, run Amiga emulator then load and start \"hstwb-build-030-jit.uae\" configuration file.\n\nWhen HstWB Installer image is built, run Amiga emulator then load and start \"hstwb-run-030-jit.uae\" configuration file.\n\nTo enable autostart for \"hstwb-run-030-jit.uae\" configuration file, load it and save it as \"autostart.uae\" configuration file. Note that autostart only works, if Raspberry Pi OS is changed to start Amiga emulator or Amiga emulator is run from \"hstwb\" menu.\n\n" 0 0

		exit
	else
		retry_menu
	fi
done
