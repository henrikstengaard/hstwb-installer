# ~/.profile: executed by Bourne-compatible login shells.
setfont Topazc.psf.gz
setterm -background blue -foreground white --bold on --store
# clear the screen
clear
export PS1="\W \$"

# install kickstart
if [ -f ~/install_kickstart.sh ]; then
	~/install_kickstart.sh -i -id=/media/usb0/kickstart -kd=/root/amibian/amiga_files/kickstarts
fi

# start emulator, if not logged in via ssh
mytty=`tty`
if [ "$mytty" == "/dev/tty1" ]; then
  bootstartingemulator
fi

# clear the screen
clear

# show the menu
menu

if [ "$BASH" ]; then
  if [ -f ~/.bashrc ]; then
    . ~/.bashrc
  fi
fi

mesg n
