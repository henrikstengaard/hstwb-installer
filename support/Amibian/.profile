# ~/.profile: executed by Bourne-compatible login shells.
setfont Topazc.psf.gz
setterm -background blue -foreground white --bold on --store
# clear the screen
clear
export PS1="\W \$"

# install kickstart
if [ -f ~/install_kickstart.sh ]; then
	~/install_kickstart.sh
fi

bootstartingemulator
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
