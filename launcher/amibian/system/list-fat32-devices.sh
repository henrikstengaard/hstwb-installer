#!/bin/bash

# List FAT32 devices
# ------------------
# Author: Henrik Noerfjand Stengaard
# Date: 2020-03-04
#
# A bash script to list FAT32 devices.

# press enter to continue
echo "List of FAT32 devices and their mountpoints"
lsblk --list --paths --output name,fstype,size,state,mountpoint | grep -e "vfat"
read -p "Press enter to continue"
