#!/bin/sh

# ------------------------------
# Add UAE Extensions bash script
# ------------------------------
#
# Author: Henrik Noerfjand Stengaard
# Date: 2017-02-23
#
# A bash script to add .uae extensions for emulationstation amiga configuration, so it will recognise .uae files as roms.
# Uae files can then be launched from emulationstation configured to run either a set of .adf or .hdf files.

# exit, if emulationstation amiga configuration already contains .uae extensions
if grep -q ">\.sh \.SH \.uae \.UAE<" /etc/emulationstation/es_systems.cfg; then
	echo "UAE extensions are already added to EmulationStation configuration!"
	exit
fi

# create backup of emulationstation configuration, if it doesn't exist
if [ ! -f /etc/emulationstation/es_systems.cfg.bak ]; then
	cp /etc/emulationstation/es_systems.cfg /etc/emulationstation/es_systems.cfg.bak
fi

# add .uae extensions to emulationstation amiga configuration
sed -e "s/>\(\.sh \.SH\)</>\1 .uae .UAE</" /etc/emulationstation/es_systems.cfg > /tmp/es_systems.cfg

# overwrite emulationstation configuration
mv -f /tmp/es_systems.cfg /etc/emulationstation/es_systems.cfg

# success message
echo "UAE extensions successfully added to EmulationStation configuration."