#!/bin/bash

# run hstwb installer config, if it exists
if [ -f ~/.hstwb-installer/config.sh ]; then
	. ~/.hstwb-installer/config.sh
fi

# hstwb installer boot 	
case "$HSTWBINSTALLERBOOT" in
hstwb)
	hstwb
	;;
emulator)
	sudo systemctl start amiberry
	;;
esac
