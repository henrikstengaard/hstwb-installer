# HstWB Installer

## Description

HstWB Installer is a set of scripts to make it easy to build an Amiga HDF image with preinstalled Workbench, WHDLoad games and/or demos incl. Arcade Game Selector 2 or iGame menu to launch games and/or demos. 

Since Amiga Workbench and Kickstart roms are licensed property these files can't be included as they need to be acquired legally by buying Cloanto Amiga Forever or using grabkick from aminet to dump roms from real Amiga's.

Setting up a blank Amiga HDF image with e.g. PFS3, Workbench, Kickstarts roms and WHDLoad games/demos installed properly can be a cumbersome task unless you spend a lot of time figuring out how this is done step by step.

This is where HstWB Installer come to aid and can help to automate such installations and should be possible for almost anyone to do with very little knowledge about Amiga. 

HstWB is short for my name and Workbench (very original, i know). 

## Images

Following Amiga HDF images are included:

* 8GB: An 8GB image with 2 partitions: DH0 500MB bootable as System:, DH1 7000MB as Work:. Both partitions are formatted with PFS3 AIO by Toni Wilen. The size of the image is adjusted so it fits an 8GB CF/SD card.

More images can manually be added to images directory compressed with zip. 

## Packages

Following packages are included and they can be selected during configuration, which will be installed automatically:

* Workbench: Workbench identified by MD5 hash from defined workbench adf directory. Files from adf's are extracted using unadf and copied to DH0:.
* Kickstart: Kickstart roms identified by MD5 hash from defined kickstart rom directory. Files are copied to DH0:Devs/Kickstarts, required for WHDLoad.
* HstWB System: Workbench configuration built by me. This is an extension of BetterWB with few files borrowed from ClassicWB.
* HstWB AGS2 Games v2.6: Arcade Game Selector 2 menu generated for WHDLoad games. This contains screenshots and details like name, publisher, Genre an year for each game. 
* HstWB AGS2 Demos v2.6: Arcade Game Selector 2 menu generated for WHDLoad demos. This contains screenshots and details like name, group and party and year for each demo. 
* HstWB iGame Games v2.6: iGame gameslist generated WHDLoad games. This iGame has names without stars, spaces and wierd characters to have a clean game list in iGame.
* HstWB iGame Demos v2.6: iGame gameslist generated WHDLoad demos. This iGame has names without stars, spaces and wierd characters to have a clean game list in iGame.
* EAB WHDLoad Games v2.6: WHDLoad games pack from EAB with update 2.6 applied.
* EAB WHDLoad Demos v2.6: WHDLoad demos pack from EAB with update 2.6 applied.

Versions are used to allow having future and updated versions of packages.

** EAB WHDLoad Games and EAB WHDLoad Demos will be provided by another script, which automatically download packs and updates from EAB ftp server, unzip, combines, packs and copies them to packages directory**

## Installation

The installation is done through WinUAE. To enable installing Workbench automatically following scripted process is used:

* Use predefined A1200 WinUAE configuration.
* A1200 identified kickstart rom is used.
* Selected Amiga HDF image it mounted as harddisk file as non-bootable.
* Install directory mounted as bootable harddisk containing. This contains a startup sequence to automate installation of identified workbench adf and kickstart rom files are copied to this directory with installation scripts and tools.
* Workbench 3.1 Workbench disk is patched to make it non-bootable. This is done by patching adf file offset 12 to 0, which make boot sector invalid and WinUAE skip booting the floppy. This enables basic commands to be loaded resident for the installation process.
* Patched Workbench 3.1 Workbench disk is mounted as DF0:.
* WinUAE is launched and startup sequence executes installation scripts and automatically shuts down, when done.

The preinstalled Amiga HDF image is now ready to use in an emulator or by writing it to a CF/SD card.
