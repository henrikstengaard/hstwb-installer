User packages for HstWB Installer
---------------------------------

This directory contains user packages for HstWB Installer and each directory represents 
a user package. A user package must contains a _installdir file with path to indicate where
the user packages will be installed.

HstWB Installer will be default copy files in a user package to path defined in _installdir
file. The installation can be customized by adding a _install AmigaDOS script file to user
package directory and make use of USERPACKAGEDIR: assign set to root of user package 
directory and $INSTALLDIR variable set to path from _installdir file.