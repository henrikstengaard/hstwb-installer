#!/bin/bash

# Audio output jack
# -----------------
# Author: Henrik Noerfjand Stengaard
# Date: 2020-04-04
#
# Bash script to set audio output to jack connector.

# show dialog
dialog --clear --stdout \
--title "Audio output to Jack" \
--yesno "Do you want to set audio output to Jack connector?" 0 0

# exit, if no is selected
if [ $? -ne 0 ]; then
  exit
fi

# set audio output to jack
amixer cset numid=3 1
