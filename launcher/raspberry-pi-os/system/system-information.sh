#!/bin/bash

# System Info
# -----------
# Author: Henrik Noerfjand Stengaard
# Date: 2020-04-05
#
# bash script to show system information.

# get cpuinfo
cpuinfo=$(cat /proc/cpuinfo)
# get cpu
cpu=$(cat /proc/cpuinfo | grep "model name" | head -n1 | sed "s/model[ ]*name[ ]*...//g")

# get model
model=$(cat /proc/device-tree/model)

# get tempature
tempature=$(vcgencmd measure_temp | sed "s/temp=//g")

# get network interfaces
network_interfaces=$(ifconfig | sed -En 's/127.0.0.1//;s/.*inet (addr:)?(([0-9]*\.){3}[0-9]*).*/\2/p')

# show system info
dialog --clear --title "System Information" --msgbox "CPU: $cpu\n\nModel: $model\n\nTempature: $tempature\n\nNetwork interfaces:\n$network_interfaces" 0 0
