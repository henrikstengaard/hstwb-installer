#!/bin/bash

# List FAT32 devices
# ------------------
# Author: Henrik Noerfjand Stengaard
# Date: 2020-04-04
#
# A bash script to list FAT32 devices.

message=$(lsblk --list --paths --output name,fstype,size,state,mountpoint | grep -e "vfat")
dialog --clear --title "List of FAT32 devices and their mountpoints" --msgbox "$message" 0 0
