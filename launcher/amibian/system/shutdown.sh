#!/bin/bash

# Shutdown
# --------
# Author: Henrik Noerfjand Stengaard
# Date: 2019-12-28
#
# A bash script for Amibian to shutdown system.


# show shutdown dialog
dialog --clear --stdout \
--title "Shutdown" \
--yesno "Do you want to shutdown system?" 0 0

# exit, if no is selected
if [ $? -ne 0 ]; then
  exit
fi

echo "Shutting down..."
shutdown -h now
