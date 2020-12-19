# fix dialog borders
export NCURSES_NO_UTF8_ACS=1

# run hstwb installer config, if it exists
if [ -f ~/.hstwb-installer/config.sh ]; then
        . ~/.hstwb-installer/config.sh
fi

# start first time use and hstwb installer boot, if not logged in via ssh
mytty=`tty`
if [ "$mytty" == "/dev/tty1" ]; then
	# run first time use, if it exist
	if [ -f ~/.hstwb-installer/.first-time-use ]; then
        	$HSTWB_INSTALLER_ROOT/launcher/raspberry-pi-os/setup/hstwb-installer/first-time-use.sh
	fi

	# hstwb installer boot
	case "$HSTWB_INSTALLER_BOOT" in
	hstwb)
        	hstwb
	        ;;
	emulator)
        	$HSTWB_INSTALLER_ROOT/launcher/raspberry-pi-os/run-amiga-emulator.sh
	        ;;
	esac
fi

# show hstwb installer launch tip
echo "Type 'hstwb' and press enter to start HstWB Installer."
