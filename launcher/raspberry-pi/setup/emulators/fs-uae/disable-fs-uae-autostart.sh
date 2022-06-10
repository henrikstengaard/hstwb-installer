#!/bin/bash -e

# Disable FS-UAE autostart
# ------------------------
# Author: Henrik Noerfjand Stengaard
# Date: 2022-01-26
#
# A bash script to disable FS-UAE autostart.


# show confirm dialog
dialog --clear --stdout \
--title "Disable FS-UAE autostart" \
--yesno "This will disable autostart for FS-UAE by deleting symlink configuration file 'autostart.fs-uae'.\n\nDo you want to disable FS-UAE autostart?" 0 0

# exit, if no is selected
if [ $? -ne 0 ]; then
  exit
fi

# disable fs-uae autostart, if it exists
if [ -s "$FSUAE_CONF_PATH/autostart.fs-uae" ]; then
	rm -f "$FSUAE_CONF_PATH/autostart.fs-uae"
fi

# show success dialog
dialog --title "Success" --msgbox "Successfully disabled FS-UAE autostart" 0 0
