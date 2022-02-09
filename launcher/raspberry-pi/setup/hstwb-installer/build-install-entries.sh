#!/bin/bash

# Build Install Entries
# ---------------------
# Author: Henrik Noerfjand Stengaard
# Date: 2022-01-10
#
# A bash script to run Build Install Entries for HstWB self install user packages.

# user packages dir
USERPACKAGES_DIR="/media/hstwb-self-install/userpackages"

# clear whdload packs dir
unset WHDLOAD_PACKS_DIR

# set whdload packs dir and script, if build install entries script exists
if [ -f "$USERPACKAGES_DIR/build_install_entries.py" ]; then
	WHDLOAD_PACKS_DIR="$USERPACKAGES_DIR"
fi

# set whdload packs dir and script, if build install entries script exists
if [ -f "$USERPACKAGES_DIR/WHDLoad Packs/build_install_entries.py" ]; then
	WHDLOAD_PACKS_DIR="$USERPACKAGES_DIR/WHDLoad Packs"
fi

# show error dialog, if user packages directory doesn't exist
if [ -z "$WHDLOAD_PACKS_DIR" ]; then
  dialog --clear --title "ERROR" --msgbox "Build install entries script 'build_install_entries.py' doesn't exist in '$USERPACKAGES_DIR' or '$USERPACKAGES_DIR/WHDLoad Packs' doesn't exist.\n\nTry Find HstWB Self Install and retry." 0 0
  exit
fi

# show build install entries dialog
dialog --clear --stdout \
--title "Build Install Entries" \
--yesno "Do you want to run Build Install Entries script 'build_install_entries.py' for HstWB Installer user packages in directory '$WHDLOAD_PACKS_DIR'?" 0 0

# exit, if no is selected
if [ $? -ne 0 ]; then
  exit
fi

# build install entries
python "$WHDLOAD_PACKS_DIR/build_install_entries.py" "$WHDLOAD_PACKS_DIR"
echo ""
read -rp "Press enter to continue..."
