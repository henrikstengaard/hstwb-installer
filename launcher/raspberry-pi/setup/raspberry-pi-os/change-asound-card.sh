#!/bin/bash

# Change asound card
# ------------------
# Author: Henrik Noerfjand Stengaard
# Date: 2022-01-12
#
# Bash script to change raspberry pi os asound card.
# Reference: https://raspberrypi.stackexchange.com/questions/95193/setting-up-config-for-alsa-at-etc-asound-conf

# show dialog
dialog --clear --stdout \
--title "Change asound card" \
--yesno "Do you want to change Raspberry Pi OS asound card?" 0 0


# exit, if no is selected
if [ $? -ne 0 ]; then
  exit
fi

# list available asound cards
grep -e "\[" -e "\]:" /proc/asound/cards >/tmp/_asound-cards.txt

# build card menu options
options=()
while read n s ; do
	options+=($n "$s")
done </tmp/_asound-cards.txt

# show select asound card dialog
cardchoice=$(dialog --clear --stdout --title "Change asound cards" --menu "Select asound card:" 0 0 0 "${options[@]}")

# exit, if cancelled
if [ -z "$cardchoice" ]; then
	exit
fi

# create or update /etc/asound.conf
sudo echo "defaults.pcm.card ${cardchoice[0]}" >/tmp/.tmp-asound.conf
sudo echo "defaults.ctl.card ${cardchoice[0]}" >>/tmp/.tmp-asound.conf
sudo cp /tmp/.tmp-asound.conf /etc/asound.conf
rm /tmp/.tmp-asound.conf
