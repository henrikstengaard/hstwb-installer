#!/bin/bash

# Enable Fake KMS driver
# ----------------------
# Author: Henrik Noerfjand Stengaard
# Date: 2022-01-13
#
# Bash script to enable fake kms driver.
# Enabled use of DispmanX, but considered legacy

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
--title "Enable Fake KMS video driver" \
--yesno "Fake KMS video driver is considered legacy, but required by UAE4ARM Amiga emulator as it uses DispmanX. Without fake KMS video driver, UAE4ARM will show a black screen. Both Amiberry and UAE4ARM Amiga emulators work with fake KMS video driver enabled.\n\nEnabling fake KMS video driver will first take effect when Raspberry Pi is rebooted.\n\nDo you want to enable fake KMS video driver?" 0 0

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
echo "dtoverlay=vc4-fkms-v3d" >>/tmp/config.txt
sudo cp /tmp/config.txt /boot/config.txt
rm /tmp/config.txt

# show reboot dialog, not install
if [ $install == 0 ]; then
	# show reboot dialog
	dialog --clear --stdout \
	--title "Reboot" \
	--yesno "Enabling fake KMS video driver will first take effect when Raspberry Pi is rebooted.\n\nDo you want to reboot now?" 0 0

	# reboot, if yes is selected
	if [ $? -eq 0 ]; then
		sudo reboot
	fi
fi
