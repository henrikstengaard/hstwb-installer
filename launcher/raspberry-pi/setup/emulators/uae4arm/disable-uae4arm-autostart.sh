#!/bin/bash -e

# Disable UAE4ARM autostart
# -------------------------
# Author: Henrik Noerfjand Stengaard
# Date: 2022-01-16
#
# A bash script to disable UAE4ARM autostart.


# show confirm dialog
dialog --clear --stdout \
--title "Disable UAE4ARM autostart" \
--yesno "This will disable autostart for UAE4ARM by renaming configuration file 'autostart.uae' to '_autostart.uae'.\n\nDo you want to disable UAE4ARM autostart?" 0 0

# exit, if no is selected
if [ $? -ne 0 ]; then
  exit
fi

# disable uae4arm autostart, if it exists
if [ -f "$UAE4ARM_CONF_PATH/autostart.uae" ]; then
	mv -f "$UAE4ARM_CONF_PATH/autostart.uae" "$UAE4ARM_CONF_PATH/autostart-disabled.uae"
fi

# show success dialog
dialog --title "Success" --msgbox "Successfully disabled UAE4ARM autostart" 0 0
