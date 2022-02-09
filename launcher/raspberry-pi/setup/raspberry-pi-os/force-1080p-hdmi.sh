#!/bin/bash

# Force 1080p HDMI
# ----------------
# Author: Henrik Noerfjand Stengaard
# Date: 2022-01-06
#
# Bash script to force set 1080p hdmi (CEA Mode 16 1920x1080 60Hz 16:9) resolution.

# install
install=0

# parse arguments
for i in "$@"
do
case $i in
    -i|--install)
    install=1
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

# show dialog
dialog --clear --stdout \
--title "Force 1080p HDMI resolution" \
--yesno "Raspberry Pi 4 / 400 uses 4K HDMI resolutions when available and this causes slow downs in Amiga emulators. Forcing HDMI resolution to 1080p will improve performance with 4K displays.\n\nForced 1080p HDMI resolution will first take effect when Raspberry Pi is rebooted.\n\nDo you want to force set 1080p HDMI (CEA Mode 16 1920x1080 60Hz 16:9) resolution?" 0 0

# exit, if no is selected
if [ $? -ne 0 ]; then
  exit
fi

# create backup of config.txt, if it doesn't exist
if [ ! -f /boot/config.txt.bak ]; then
  sudo cp /boot/config.txt /boot/config.txt.bak
fi

# update config.txt
echo "# force 1080p hdmi resolution" >/tmp/config.txt
echo "hdmi_ignore_edid=0xa5000080" >>/tmp/config.txt
echo "hdmi_group=1" >>/tmp/config.txt
echo "hdmi_mode=16" >>/tmp/config.txt
sudo sed -e "s/^\(hdmi_ignore_edid=\)/#\1/gi" -e "s/^\(hdmi_group=\)/#\1/gi" -e "s/^\(hdmi_mode=\)/#\1/gi" /boot/config.txt >>/tmp/config.txt
sudo cp /tmp/config.txt /boot/config.txt
rm /tmp/config.txt

# show reboot dialog, not install
if [ $install == 0 ]; then
	# show reboot dialog
	dialog --clear --stdout \
	--title "Reboot" \
	--yesno "Forced 1080p HDMI resolution will first take effect when Raspberry Pi is rebooted.\n\nDo you want to reboot now?" 0 0

	# reboot, if yes is selected
	if [ $? -eq 0 ]; then
		sudo reboot
	fi
fi
