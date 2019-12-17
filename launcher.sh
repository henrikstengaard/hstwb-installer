#!/bin/bash

# Launcher
# --------
# Author: Henrik Noerfjand Stengaard
# Date: 2019-12-17
#
# bash script to launch HstWB Installer.

# start amibian launcher menu
if [ -f "/root/amibian/.amibian_version" ]; then
	pushd launcher/amibian
	./launcher.sh
	popd
	exit
fi

echo "Unsupported environment"
exit 1
