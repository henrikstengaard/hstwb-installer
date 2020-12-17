#!/bin/bash -e

# HstWB Installer Uninstall
# -------------------------
# Author: Henrik Noerfjand Stengaard
# Date: 2020-04-04
#
# A bash script to uninstall HstWB Installer launcher for Amibian.

# show uninstall dialog
dialog --clear --stdout \
--title "Uninstall HstWB Installer" \
--yesno "This will remove HstWB Installer configuration and patches installed by HstWB Installer. Main HstWB Installer application and scripts will not be removed and HstWB Installer can be installed again be running './install.sh' script.\n\nDo you want to uninstall HstWB Installer?" 0 0

# exit, if no is selected
if [ $? -ne 0 ]; then
  exit
fi

# restore backup of rc.local, if it exist
if [ -f /etc/rc.local_backup -a -f /etc/rc.local ]; then
	sudo cp /etc/rc.local_backup /etc/rc.local
fi

# restore backup of usbmount.conf, if it exist
if [ -f /etc/usbmount/usbmount.conf_backup -a -f /etc/usbmount/usbmount.conf ]; then
	sudo cp /etc/usbmount/usbmount.conf_backup /etc/usbmount/usbmount.conf
fi

# delete hstwb installer profile, if it exist
if [ -d ~/.hstwb-installer ]; then
        rm -Rf ~/.hstwb-installer
fi

# delete hstwb from bin
if [ -f "/usr/local/bin/hstwb" ]; then
	rm "/usr/local/bin/hstwb"
fi

# restore backup of profile, if it exist
if [ -f ~/.profile_backup -a -f ~/.profile ]; then
	cp ~/.profile_backup ~/.profile
fi

# remove hstwb from amibian 1.5 menu
if [ -f ~/.amibian_scripts/show_menu.sh -a "$(grep -i "cat ~/.hstwb-installer/menu_files/hstwb" ~/.amibian_scripts/show_menu.sh)" != "" ]; then
	grep -iv "cat ~/.hstwb-installer/menu_files/hstwb" ~/.amibian_scripts/show_menu.sh >/tmp/_show_menu.sh
	mv /tmp/_show_menu.sh ~/.amibian_scripts/show_menu.sh
	chmod +x ~/.amibian_scripts/show_menu.sh
fi

# remove hstwb from amibian 1.4.1001 menu
if [ -f /usr/local/bin/menu -a "$(grep -i "cat ~/.hstwb-installer/menu_files/hstwb" /usr/local/bin/menu)" != "" ]; then
	grep -iv "cat ~/.hstwb-installer/menu_files/hstwb" /usr/local/bin/menu >/tmp/_menu
	mv /tmp/_menu /usr/local/bin/menu
	chmod +x /usr/local/bin/menu
fi

# show success dialog
dialog --clear --title "Success" --msgbox "Successfully uninstalled HstWB Installer." 0 0


