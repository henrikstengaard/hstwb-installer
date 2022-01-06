#!/bin/bash

# About
# -----
# Author: Henrik Noerfjand Stengaard
# Date: 2022-01-06
#
# bash script to show hstwb installer about.

# get version
version=$(git describe --tags)

# get updated date
date=$(git log -1 --format=%cd)

# show about dialog
dialog --clear --title "About HstWB Installer" --msgbox "HstWB Installer v$version\nUpdated: $date\n\nCreated and maintained by\nHenrik Nørfjand Stengaard\n\nWebsite: https://hstwb.firstrealize.com\nEmail: hstwbinstaller@gmail.com" 0 0
