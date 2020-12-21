#!/bin/bash -e

# Disable autostart
# -----------------
# Author: Henrik Noerfjand Stengaard
# Date: 2020-12-21
#
# A bash script to disable Amiberry autostart.


# show confirm dialog
dialog --clear --stdout \
--title "Disable Amiberry autostart" \
--yesno "This will disable autostart for Amiberry by renaming configuration file 'autostart.uae' to '_autostart.uae'.\n\nDo you want to disable Amiberry autostart?" 0 0

# exit, if no is selected
if [ $? -ne 0 ]; then
  exit
fi

# disable amiberry autostart, if it exists
if [ -f "$AMIBERRY_CONF_PATH/autostart.uae" ]; then
	mv -f "$AMIBERRY_CONF_PATH/autostart.uae" "$AMIBERRY_CONF_PATH/_autostart.uae"
fi

# show success dialog
dialog --title "Success" --msgbox "Successfully disabled Amiberry autostart" 0 0
