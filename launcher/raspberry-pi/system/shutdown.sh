#!/bin/bash

# Shutdown
# --------
# Author: Henrik Noerfjand Stengaard
# Date: 2021-01-05
#
# A bash script for raspberry pi os to shutdown system.


# show shutdown dialog
dialog --clear --stdout \
--title "Shutdown" \
--yesno "Do you want to shutdown system?" 0 0

# exit, if no is selected
if [ $? -ne 0 ]; then
  exit
fi

echo "Shutting down..."
sudo shutdown -h now
