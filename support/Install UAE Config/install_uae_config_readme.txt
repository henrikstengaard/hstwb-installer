Install UAE Config Readme
-------------------------

Install UAE Config is a set of scripts to install WinUAE and FS-UAE config files
for HstWB images by patching directories to where the directory the image is located
and install WinUAE and FS-UAE config files in WinUAE and FS-UAE's default 
installation directory. The scripts are written in both Powershell and Python for 
cross platform Windows, Mac OS X and Linux support and comes with extra files so they
can easily be run directly from Windows Explorer, Mac OS X Finder and Ubuntu Files.

Install UAE Config will patch and install WinUAE and FS-UAE config files. Patching
updates hard drive directories to current directory, changes Kickstart rom file and
adds adf files as swappable floppies for FS-UAE only. Install copies patched
WinUAE and FS-UAE config files to default configuration directory for WinUAE and
FS-UAE. For Windows install copies Workbench 3.1 adf files and Kickstart rom files
from Cloanto Amiga Forever, if it's installed. 

When hard drive directories are patched to use current directory, Install UAE Config
will create following sub-directories, if present in WinUAE or FS-UAE config files:
- Workbench: Directory with Workbench adf files.
- Kickstart: Directory with Kickstart rom files.
- OS39: Directory with Amiga OS 3.9 iso and boing bag 1 & 2 files.
- UserPackages: Directory with user packages.

Kickstart rom file is patched to use Amiga 1200 Kickstart 3.1 rom, if it exists in
Kickstart directory.

For FS-UAE config file, .adf files in Workbench directory are added as swappable
floppies.


Install WinUAE and FS-UAE config files for Windows 7+
-----------------------------------------------------

Prerequisites:
- WinUAE and FS-UAE installed and started once to create default configuration 
  directories.

Install WinUAE and FS-UAE config files for Windows 7+ with the following steps:
1. Double-click "install_uae_config.cmd" in Windows Explorer to patch and install
   WinUAE and FS-UAE config files. Workbench 3.1 adf files and Kickstart rom files
   are automatically copied from Cloanto Amiga Forever, if it's installed.
2. For HstWB self install image, copy Workbench 3.1 adf files to Workbench directory,
   Kickstart rom files to Kickstart directory and copy Amiga OS 3.9 iso (must be
   named "amigaos3.9.iso") and boing bag 1 & 2 to OS39 directory, if installing
   Amiga OS 3.9.
3. Double-click "install_uae_config.cmd" in Windows Explorer to patch and install
   WinUAE and FS-UAE config files with updated Kickstart and OS39 directories. 
4. WinUAE and FS-UAE now has a hstwb-installer configuration ready to use.


Install FS-UAE config file for Mac OS X
---------------------------------------

Prerequisites:
- FS-UAE installed and started once to create default configuration 
  directories.

Install FS-UAE config file for Mac OS X with the following steps:
1. Double-click "install_uae_config.command" in Finder to patch and install
   FS-UAE config file.
2. Press CTRL+Q to close terminal window with Install UAE Config output.
3. For HstWB self install image, copy Workbench 3.1 adf files to Workbench directory,
   Kickstart rom files to Kickstart directory and copy Amiga OS 3.9 iso (must be
   named "amigaos3.9.iso") and boing bag 1 & 2 to OS39 directory, if installing
   Amiga OS 3.9.
4. Double-click "install_uae_config.command" in Finder to patch and install
   FS-UAE config file with updated Kickstart and OS39 directories. 
5. Press CTRL+Q to close terminal window with Install UAE Config output.
6. FS-UAE now has a hstwb-installer configuration ready to use.


Install FS-UAE config file for Linux
------------------------------------

Prerequisites:
- FS-UAE installed and started once to create default configuration 
  directories.

Install FS-UAE config file for Linux with the following steps:
1. Run "install_uae_config.sh" from shell or terminal to patch and install
   FS-UAE config file. For Ubuntu, double-click "install_uae_config.desktop" in Files.
   This requires execute permission, which can be added by right-click 
   "install_uae_config.desktop", select properties, permissions tab and check "Allow
   executing file as a program".
2. For HstWB self install image, copy Workbench 3.1 adf files to Workbench directory,
   Kickstart rom files to Kickstart directory and copy Amiga OS 3.9 iso (must be
   named "amigaos3.9.iso") and boing bag 1 & 2 to OS39 directory, if installing
   Amiga OS 3.9.
3. Run "install_uae_config.sh" from shell or terminal to patch and install
   FS-UAE config file. For Ubuntu, double-click "install_uae_config.desktop" in Files.
4. FS-UAE now has a hstwb-installer configuration ready to use.
