#!/bin/bash

# Build Install Entries
# ---------------------
# Author: Henrik Noerfjand Stengaard
# Date: 2018-05-21
#
# A bash script for Amibian to run Build Install Entries for HstWB Installer user packages.


# user packages directory
userpackagesdir="/media/usb0/userpackages"

# show error dialog, if user packages directory doesn't exist
if [ ! -d "$userpackagesdir" ]; then
  dialog --clear --title "ERROR" --msgbox "User packages directory '$userpackagesdir' doesn't exist." 0 0
  exit
fi

# show error dialog, if user packages directory doesn't exist
if [ ! -f "$userpackagesdir/build_install_entries.py" ]; then
  dialog --clear --title "ERROR" --msgbox "Build install entries script '$userpackagesdir/build_install_entries.py' doesn't exist." 0 0
  exit
fi

# show build install entries dialog
dialog --clear --stdout \
--title "Build Install Entries" \
--yesno "Do you want to run Build Install Entries for HstWB Installer user packages in directory '$userpackagesdir'?" 0 0

# exit, if no is selected
if [ $? -ne 0 ]; then
  exit
fi

# build install entries
python "$userpackagesdir/build_install_entries.py" "$userpackagesdir"
echo ""
read -rp "Press enter to continue..."