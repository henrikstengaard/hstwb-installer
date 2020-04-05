#!/bin/bash

# Run Amiga Emulator
# ------------------
# Author: Henrik Noerfjand Stengaard
# Date: 2020-04-05
#
# bash script to show hstwb installer about.

# get version
version=$(git describe --tags)

# get updated date
date=$(git log -1 --format=%cd)

# show about dialog
dialog --clear --title "About HstWB Installer" --msgbox "HstWB Installer v$version\nUpdated: $date\n\nCreated and maintained by\nHenrik Nørfjand Stengaard\n\nWebsite: hstwb.firstrealize.com" 0 0
