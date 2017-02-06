# HstWB Installer

## Description

HstWB Installer is a set of scripts to make it easy to build an Amiga HDF image with preinstalled Workbench, WHDLoad games and/or demos incl. Arcade Game Selector 2 or iGame menu to launch games and/or demos. 

Since Amiga Workbench and Kickstart roms are licensed property these files can't be included as they need to be acquired legally by buying Cloanto Amiga Forever or using grabkick from aminet to dump roms from real Amiga's.

Setting up a blank Amiga HDF image with e.g. PFS3, Workbench, Kickstarts roms and WHDLoad games/demos installed properly can be a cumbersome task unless you spend a lot of time figuring out how this is done step by step.

This is where HstWB Installer come to aid and can help to automate such installations and should be possible for almost anyone to do with very little knowledge about Amiga. 

*HstWB is short for my name and Workbench (very original, I know).* 

## User interface

Currently the plan is to make the following user interfaces for HstWB-Installer:

* Powershell: Windows powershell script launched from console or Windows Explorer via cmd script.
* Bash: Mac/Linux script launched from terminal.

Powershell script can be extended to use WinForms to present a Windows application, which makes it much more user friendly, but this has low priority. First priority is to make a powershell script, that can perform an automated installation of packages to an Amiga HDF image. 

Something similar could be used for Mac/Linux, but I'm not aware of whats possible there. 

Using Mac/Linux would also require use of FS-UAE emulator.

## Image templates

HstWB Installer has following image templates included:

1. 4GB: HDF RDB, DH0 (100MB/PFS3), DH1 (3500MB/PFS3)
2. 4GB: HDF RDB, DH0 (300MB/PFS3), DH1 (3300MB/PFS3)
3. 8GB: HDF RDB, DH0 (100MB/PFS3), DH1 (7200MB/PFS3)
4. 8GB: HDF RDB, DH0 (300MB/PFS3), DH1 (7000MB/PFS3)
5. 16GB: HDF RDB, DH0 (300MB/PFS3), DH1 (13100MB/PFS3)
6. RaspBerry Pie: DH0 (100MB/FFS/HDF), DH1 (DIR)
7. RaspBerry Pie: DH0 (300MB/FFS/HDF), DH1 (DIR)

4GB, 8GB and 16GB images are RDB HDF's using PFS3 AIO filesystem by Toni Wilen and are formatted with pfsformat filename size of 107 characters. Partitions are created with HDToolbox and configured with MaxTransfer value 0x1fe00. HDF files for these images are created so they are ~100MB smaller than various CF/SD cards, so they can be written to CF/SD card using eg. Win32DiskImager for use in real Amiga's.

RaspBerry Pie images doesn't use RDB as UAE4Arm doesn't support it and uses a directory mounted as DH1, so it can contain more than 1-2GB of games and demos. The limit is then bound to the size of SD card. Using Samba/Windows share "\\retropie\roms\amiga\hstwb\dh1" gives direct access to DH1 partition making it easy to manage content.

---

An image template for HstWB Installer is a zip file containing set of HDF and configuration files, which are used to build a new image.

Each image template zip file contains the following files:

1. image.ini (Required): Ini file with image name.
2. harddrives.uae (Required): WinUAE configuration of harddrives for image with [$ImageDir] and [$ImageDirEscaped] placeholders replaced with directory containing image files, when HstWB Installer is launched.
3. disk.hdf (Optional): One or more HDF files ready for use and configured in harddrives.uae.

Image.ini example:
###
    [Image]
    Name=4GB: HDF RDB, DH0 (100MB/PFS3), DH1 (3500MB/PFS3)

Harddrives.uae example:
###
    hardfile2=rw,DH0:[$ImageDir]\4gb.hdf,0,0,0,512,0,,uae
    uaehf0=hdf,rw,DH0:"[$ImageDirEscaped]\\4gb.hdf",0,0,0,512,0,,uae

A new image can be created using the setup script by selecting create a new image directory from image template. 
It will read harddrives.uae file from the image zip file, extract HDF's and create directories defined in "uaehf" lines.

When HstWB Installer is launched, it reads harddrives.uae file from the image directory and merges it into it's WinUAE configuration. 
Placeholders [$ImageDir] and [$ImageDirEscaped] are replaced with the ImageDir configured in HstWB Installer settings.
As an example, the placeholders will be replaced by the following, if ImageDir is configured to "C:\Temp\HstWB-4GB":
###
    [$ImageDir] -> C:\Temp\HstWB-4GB
    [$ImageDirEscaped] -> C:\\Temp\\HstWB-4GB

The escaped is needed for quoted paths like:
###
    uaehf0=hdf,rw,DH0:"[$ImageDirEscaped]\\4gb.hdf",0,0,0,512,0,,uae

Own image templates can be created by following the examples above or use files from one of the existing image templates to get started. Configuration of harddrives.uae can directly be copied from a saved WinUAE configuration, just replace directory paths with placeholders as mentioned above. 

## Packages

Following packages are included and they can be selected during configuration, which will be installed automatically:

* Workbench: Workbench identified by MD5 hash from defined workbench adf directory. Files from adf's are extracted using unadf and copied to DH0:.
* Kickstart: Kickstart roms identified by MD5 hash from defined kickstart rom directory. Files are copied to DH0:Devs/Kickstarts, required for WHDLoad.
* HstWB System: Workbench configuration built by me. This is an extension of BetterWB with few files borrowed from ClassicWB.
* HstWB AGS2 EAB WHDLoad Games v2.6: Arcade Game Selector 2 menu generated for WHDLoad games. This contains screenshots and details like name, publisher, Genre an year for each game. 
* HstWB AGS2 EAB WHDLoad Demos v2.6: Arcade Game Selector 2 menu generated for WHDLoad demos. This contains screenshots and details like name, group and party and year for each demo. 
* HstWB iGame EAB WHDLoad Games v2.6: iGame gameslist and screenshots generated for WHDLoad games. This gameslist has names without stars, spaces and wierd characters to have a clean game list in iGame.
* HstWB iGame EAB WHDLoad Demos v2.6: iGame gameslist and screenshots generated for WHDLoad demos. This gameslist has names without stars, spaces and wierd characters to have a clean game list in iGame.
* EAB WHDLoad Games v2.6: WHDLoad games pack from EAB with update 2.6 applied.
* EAB WHDLoad Demos v2.6: WHDLoad demos pack from EAB with update 2.6 applied.

Versions are used to allow having future and updated versions of packages.

**EAB WHDLoad Games and EAB WHDLoad Demos will be provided by another script, which automatically download packs and updates from EAB ftp server, unzip, combines, packs and copies them to packages directory**

## Package files and their structure

A package is zip file located in the packages directory. Packages are identified by the following naming convention:

[name].[version].zip

Selected packages are extracted when installation is being prepared and processed one by one during installation. Before executing a packages install script, the following assign are defined:
- PACKAGEDIR: Path to directory containing the package.

As a bare minimum a package must contain the following files:

- install: AmigaOS script to perform installation is the package.
- package.ini: Ini file describing the content of the package including name, description, version.

Any other files can be part of a package as resources to install.

Here is the contents of HstWB.1.0.0.zip package:
- install: AmigaOS script extracting hstwb.zip.
- hstwb.zip: Zip archive with HstWB files to install.

Packages are kept simple, so they are easy to build and maintain.

## HstWB Installation Process

The installation is done through WinUAE. To enable installing Workbench automatically following scripted process is used:

* Use predefined A1200 WinUAE configuration.
* Identified A1200 kickstart rom is used.
* Selected Amiga HDF image is mounted as harddisk file non-bootable.
* Install directory mounted as bootable harddisk. This contains a startup sequence to automate installation of identified workbench adf and kickstart rom files, which are copied to this directory with installation scripts and tools.
* Identified Workbench 3.1 Workbench disk is used.
* Workbench 3.1 Workbench disk is patched to make it non-bootable. This is done by patching adf file offset 12 to 0, which make boot sector invalid and WinUAE skip booting the floppy. 
* Patched Workbench 3.1 Workbench disk is mounted as DF0:.
* The mounted non-bootable Workbench disk allows basic commands to be loaded resident for the installation process initiated by startup sequence in mounted install directory.
* WinUAE is launched and startup sequence executes installation scripts and automatically shuts down, when it's done.

The preinstalled Amiga HDF image is now ready to use in an emulator.

## Requirements

The minimum requirements for running HstWB Installer are:

* Windows 7, 8, 8.1 or 10.
* Cloanto Amiga Forever installed or dumps of own Workbench adf files and Kickstart rom files located in a directory.
* WinUAE.

## Installation

Installation is quite easy and can be done one the following ways: 

* Clone git repository.
* Click 'Download ZIP' and extract files.

## Usage

**Menu using setup script**

First run HstWB Installer Setup script to configure settings. Default settings are used, if settings file "hstwb-installer-settings.ini" doesn't exist. Each time a setting is changed the settings file is updated or auto saved. When choosing Workbench adf or Kickstart rom set, files in configured directories are examined to find valid Workbench adf and Kickstart rom files required for installation process. Select the set that has all files detected. 

For users with Cloanto Amiga Forever installed, following steps will create a new 8gb image and install Workbench, Kickstart roms:

1. Double-click 'hstwb-installer-setup.cmd' in Windows Explorer or start 'hstwb-installer-setup.ps1' from powershell to run setup script.
2. Type 1 and enter to enter select image menu.
3. Type 2 and enter to enter new image menu.
4. Type 1 and enter to select 8gb image.
5. Type "test.hdf" and press enter.
6. Type 3 and enter to go back to main menu.
7. Type 6 and enter run installer, wait for WinUAE to complete installation process.
8. Press enter to continue.
9. Type 8 and enter to exit.

**Manual using run script**

The settings file "hstwb-installer-settings.ini" can also be created manually with the following content:

###
    [Image]
    HdfImagePath=C:\Users\Public\Documents\Amiga Files\Shared\hdf\test.hdf
    [Kickstart]
    InstallKickstart=Yes
    KickstartRomPath=C:\Users\Public\Documents\Amiga Files\Shared\rom
    KickstartRomSet=Kickstart Cloanto Amiga Forever 2016
    [Winuae]
    WinuaePath=C:\Program Files (x86)\WinUAE\winuae.exe
    [Workbench]
    InstallWorkbench=Yes
    WorkbenchAdfPath=C:\Users\Public\Documents\Amiga Files\Shared\adf
    WorkbenchAdfSet=Workbench 3.1 Cloanto Amiga Forever 2016

Double-click 'hstwb-installer-run.cmd' in Windows Explorer or start 'hstwb-installer-run.ps1' from powershell to run installer script.

## Screenshots

![HstWB Installer running automated installation of Workbench](https://raw.githubusercontent.com/henrikstengaard/hstwb-installer/master/screenshots/hst-wb_installer_running1.png)
![HstWB Installer running automated installation of Kickstart roms](https://raw.githubusercontent.com/henrikstengaard/hstwb-installer/master/screenshots/hst-wb_installer_running2.png)
![Preinstalled image booted in WinUAE showing Workbench](https://raw.githubusercontent.com/henrikstengaard/hstwb-installer/master/screenshots/preinstalled_workbench.png)