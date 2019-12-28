# ~/.profile: executed by Bourne-compatible login shells.
setterm -background blue -foreground white --bold on --store
# clear the screen
clear
export PS1="\W \$"

# run hstwb installer config, if it exists
if [ -f ~/.hstwb-installer/config.sh ]; then
	. ~/.hstwb-installer/config.sh
fi

# run first boot, if it doesn't exist
if [ ! -f ~/.hstwb-installer/.first-boot ]; then
	~/.hstwb-installer/first-boot.sh
	touch ~/.hstwb-installer/.first-boot
fi

# clear the screen
clear

if [ "$BASH" ]; then
  if [ -f ~/.bashrc ]; then
    . ~/.bashrc
  fi
fi

mesg n

# start emulator, if not logged in via ssh
mytty=`tty`
if [ "$mytty" != "/dev/tty1" ]; then
  menu
  exit
fi

# hstwb installer boot 	
case "$HSTWBINSTALLERBOOT" in
hstwb)
	hstwb
	;;
emulator)
	bootstartingemulator
	;;
esac

menu
