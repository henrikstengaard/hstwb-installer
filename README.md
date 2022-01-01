# HstWB Installer

HstWB Installer is an application, which can automate installation of Amiga OS, Kickstarts roms and packages with additional content. 

Creating new harddrive images for Amiga and installing Amiga OS, Kickstart roms, ClassicWB, WHDLoad games and demos properly can be a cumbersome task unless you spend a lot of time figuring out how this is done step by step.

This is where HstWB Installer come to aid and can help simplifying installations and make it possible for almost anyone to do with very little knowledge about Amiga.

## Basics

HstWB Installer comes with prepared image templates partitioned, formatted and ready to use for creating a new installation of Amiga OS. It supports automated installation of Amiga OS 3.2, 3.1.4 and 3.1 from floppy disks or adf files and Amiga OS 3.9 from cd-rom or iso file. 

Kickstart roms for WHDLoad are detected by checking rom file MD5 checksums and installed on Amiga system device along with Cloanto Amiga Forever rom key depending on rom files are encrypted or not. Afterwards additional content can be installed with packages and user packages. 

Packages simplifies installation of Workbench enhancements BetterWB, ClassicWB and HstWB together with demo and game launchers Amiga Games Selector 2, iGame and HstLauncher with screenshots and descriptions for each demo and game. 

User packages simplifies installation of EAB WHDLoad demo and game packs and can be used for additional simple installations by copying files from host OS running HstWB Installer to various drawers in Amiga harddrive image.

A minimalistic approach is possible without installing any packages or user packages, which allows own installation of eg. MagicWB or Scalos Workbench enhancements.

HstWB Installer can create new images using install and build self install mode. Install mode installs selected Amiga OS, Kickstart roms, packages and user packages ready for use. Build self install mode builds a self install image with selected packages. 

Running a self install image detects and installs provided Amiga OS and Kickstart roms. Afterwards packages and user packages can be selected and installed making the image ready for use. 

Both install and self install uses the same installation process, which is written in AmigaDOS scripts and uses binaries for 68000 CPU to support as many Amiga models as possible. HstWB Installer uses WinUAE or FS-UAE emulator to run the installation process.

## Licensed files required

Amiga OS and Kickstart roms are licensed property and still sold commercially. Therefore use of HstWB Installer requires Amiga OS and Kickstart roms files, floppy disks or cd-roms, which can be bought legally from Cloanto Amiga Forever, Hyperion Entertainment and online Amiga stores. 

It's also possible to dump required files on a real Amiga using tsgui to dump Amiga OS floppy disks to adf files and grabkick to dump Kickstart roms to rom files. Both tsgui and grabkick can be downloaded from http://aminet.net.

## Background

HstWB Installer started as a Workbench enhancement called HstWB and evolved into an idea about how prepared Amiga harddrive images ready for use could be shared publically for download without licenced Amiga OS and Kickstart roms files. 

This formed a solution similar to ClassicWB, where a prepared Amiga harddrive image can be started and install required Amiga OS files during it's first time startup. 

Within short time this turned into a configurable way of automating installation of Amiga OS 3.1 and Kickstart roms used for WHDLoad. 

To give users the choice of installing additional content on a freshly installed Amiga OS, the packages concept was introduced. Then WHDLoad demo and game launcher packages with screenshot was added together with various versions of the very popular ClassicWB and BetterWB Workbench enhancements.

The name of the project "HstWB" is short for Henrik Nørfjand Stengaard who is currently developing and maintaining HstWB Installer.

# License

HstWB Installer is licensed under MIT license, see LICENSE.txt file.

# Requirements

The minimum requirements for running and using HstWB Installer are:

* Windows 7, 8, 8.1 or 10.
* WinUAE or FS-UAE Amiga emulator.
* Amiga OS and Kickstart rom files from Cloanto Amiga Forever or own dumps from real Amiga.

The minimum requirements for running self install images are:

* WinUAE, FS-UAE, Amiberry, UAE4ARM or similar Amiga emulator.
* Amiga OS and Kickstart rom files from Cloanto Amiga Forever or own dumps from real Amiga.

# Documentation, installation, quickstarts and tutorials

HstWB Installer GitHub Wiki contains documentation and details about installation, quickstarts and tutorials using HstWB Installer.

Please start by reading [How to use HstWB Installer](https://github.com/henrikstengaard/hstwb-installer/wiki/How-to-use-HstWB-Installer) for a quickstart about how to use HstWB Installer.