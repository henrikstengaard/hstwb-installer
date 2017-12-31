User packages for HstWB Installer
---------------------------------

This directory contains user packages for HstWB Installer and is copied to image directory, 
when building a self install image. Each directory represents a user package and is valid, 
if it contains a _installdir file with path to indicate where the user packages will
be installed.
By default a user package is copied to path defined in _installdir. It's also possible to
add a _install file for customizing installation a user package. This useful for extracting
.lha, .zip archives or modify e.g. startup-sequence with a new assign.