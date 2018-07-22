#!/bin/bash

# Clean Amibian
# -------------
# Author: Henrik Noerfjand Stengaard
# Date: 2018-04-02
#
# A bash script to clean Amibian for release.

# clean tmp
if [ -d /tmp ]; then
	rm -rf /tmp/*
fi

# remove persistent net file
if [ -f /etc/udev/rules.d/70-persistent-net.rules ]; then
	rm -f /etc/udev/rules.d/70-persistent-net.rules
fi

# clean bash history
if [ -f ~/.bash_history ]; then
	echo -n "" >~/.bash_history
fi