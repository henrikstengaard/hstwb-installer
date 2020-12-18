#!/bin/bash

# Run Midnight Commander
# ----------------------
# Author: Henrik Noerfjand Stengaard
# Date: 2020-12-18
#
# A bash script to install and run Midnight Commander.

# search for mc in installed packages
dpkg -s mc >/dev/null 2>&1

# install mc, package is not installed
if [ $? -ne 0 ]; then
	sudo apt-get --assume-yes install mc
fi

# run mc
mc
