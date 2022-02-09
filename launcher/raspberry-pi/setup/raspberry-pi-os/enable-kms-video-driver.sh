#!/bin/bash

# Enable KMS driver
# -----------------
# Author: Henrik Noerfjand Stengaard
# Date: 2022-01-13
#
# Bash script to enable kms driver.

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
--title "Enable KMS video driver" \
--yesno "KMS video driver is default with Raspberry Pi OS. It only works with Amiberry Amiga emulator and not UAE4ARM Amiga emulator.\n\nEnabling KMS video driver will first take effect when Raspberry Pi is rebooted.\n\nDo you want to enable KMS video driver?" 0 0

# exit, if no is selected
if [ $? -ne 0 ]; then
  exit
fi

# create backup of config.txt, if it doesn't exist
if [ ! -f /boot/config.txt.bak ]; then
  sudo cp /boot/config.txt /boot/config.txt.bak
fi

# update config.txt
sudo sed -e "s/^\(dtoverlay=\)/#\1/gi" /boot/config.txt >>/tmp/config.txt
echo "dtoverlay=vc4-kms-v3d" >>/tmp/config.txt
sudo cp /tmp/config.txt /boot/config.txt
rm /tmp/config.txt

# show reboot dialog, not install
if [ $install == 0 ]; then
	# show reboot dialog
	dialog --clear --stdout \
	--title "Reboot" \
	--yesno "Enabling KMS video driver will first take effect when Raspberry Pi is rebooted.\n\nDo you want to reboot now?" 0 0

	# reboot, if yes is selected
	if [ $? -eq 0 ]; then
		sudo reboot
	fi
fi
