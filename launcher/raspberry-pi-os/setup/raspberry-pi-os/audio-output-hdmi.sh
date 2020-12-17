#!/bin/bash

# Audio output hdmi
# -----------------
# Author: Henrik Noerfjand Stengaard
# Date: 2020-04-04
#
# Bash script to set audio output to hdmi connector.

# show dialog
dialog --clear --stdout \
--title "Audio outut to HDMI" \
--yesno "Do you want to set audio output to HDMI connector?" 0 0

# exit, if no is selected
if [ $? -ne 0 ]; then
  exit
fi

# set audio output to hdmi
amixer cset numid=3 2
