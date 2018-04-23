Amibian HstWB Installer
-----------------------
Author: Henrik Noerfjand Stengaard
Date: 2018-04-23

Amibian HstWB Installer is a preconfigured setup of Amibian with
ready-made harddrives and configs for Amiberry and Chips UAE4ARM
emulators.

It's created to make installation of your Amiga setup as simple 
as possible with users providing their own Workbench 3.1 adf files,
Kickstart rom files and Amiga OS 3.9 files.


Preparation
-----------

1. Write amibian_hstwb-installer.img to sd-card with Win32 Disk
   Imager, ApplePi Baker, dd or similar imaging tool.
2. FAT32 format a usb stick and extract hstwb_installer_install.zip
   to root of the usb stick.
3. Copy install files to usb stick:
   1. Copy required Kickstart rom files to "kickstart" directory.
      HstWB Installer supports Cloanto Amiga Forever 2016 & 7 and 
      original dumps of Kickstart rom files. For Cloanto Amiga 
      Forever copy Kickstart rom files from Cloanto Amiga Forever 
      data directory e.g.
      "c:\users\public\documents\amiga files\shared\rom".
   2. Copy required Workbench 3.1 adf files to "workbench" directory.
      HstWB Installer supports Cloanto Amiga Forever 2016 & 7 and
      original dumps of Workbench 3.1 adf files. For Cloanto Amiga
      Forever copy Workbench adf files from Cloanto Amiga Forever
      data directory e.g. 
      "c:\users\public\documents\amiga files\shared\adf".
   3. Copy optional Amiga OS 3.9 iso file, Boing Bag 1 & 2 lha
      files to "os39" directory. This is only required for Amiga
      OS 3.9 and ClassicWB 3.9 installation and will automatically
      install Amiga OS 3.9 over Workbench 3.1. HstWB Installer 
      requires Amiga OS 3.9 iso is named "AmigaOS3.9.iso", Boing 
      Bag 1 is named "BoingBag39-1.lha" and Boing Bag 2 is named 
      "BoingBag39-2.lha" (it's not case sensitive).
   4. Copy optional EAB WHDLoad Packs downloaded from
      EAB File Server to "userpackages" directory. HstWB Installer
      Wiki has a "Prepare self install tutorial" at 
      https://github.com/henrikstengaard/hstwb-installer/wiki/Prepare-self-install-tutorial
      describing step by step how to download and prepare EAB 
      WHDLoad Packs.
      EAB WHDLoad Packs directories must be copied or moved to
      following directories in "userpackages" directory:
      - Copy or move files from "Commodore_Amiga_-_WHDLoad_-_Demos"
        to "eab-whdload-demos".
      - Copy or move files from "Commodore_Amiga_-_WHDLoad_-_Games"
        to "eab-whdload-games".
      - Copy or move files from 
        "Commodore_Amiga_-_WHDLoad_-_Games_(Beta_&_Unreleased)"
        to "eab-whdload-games_beta".
      Run Build EAB WHDLoad Install:
      - Windows: Double-click "build_eab_whdload_install.cmd" in
        Windows Explorer.
      - macOS: Double-click "build_eab_whdload_install.command" in
        Finder.
      - Ubuntu: Double-click "Build EAB WHDLoad Install" in
        Ubuntu Files.
      - Linux: Type "./build_eab_whdload_install.sh" and press 
        enter in terminal.


Installation
------------

1. Insert sd-card and usb stick in Raspberry Pi.
2. Turn power on.
3. Expand filesystem dialog is shown asking to expand filesystem
   to sd-card size. This is only shown once, but can be started
   again by typing "~/expand_filesystem.sh" in terminal.
4. Select emulator dialog is shown to select emulator
   to use for HstWB Installer. This is only shown once, but can
   be started again by typing "~/select_emulator.sh" in terminal. 
5. Install kickstart script run is started to automatically
   install A1200 Kickstart rom "kick31.rom" for Chips UAE4ARM and
   Amiberry, if it doesn't already exist. Dialogs are shown to 
   indicate, if installation was successful or an error occured.
   If A1200 Kickstart rom a select install directory dialog is
   shown to select a different install directory and retry
   install kickstart. Install kickstart can be started again by
   typing "~/install_kickstart.sh" in terminal.
6. Follow HstWB Installer messages to complete installation of
   Workbench 3.1, Kickstart roms, Amiga OS 3.9 and packages.
   HstWB Installer Wiki has a "Run self install tutorial" at
   https://github.com/henrikstengaard/hstwb-installer/wiki/Run-self-install-tutorial
   describing step by step how to run self install with
   screenshots.
   For an example setup install packages: BetterWB, HstWB, 
   EAB WHDLoad Demos Menu v3.0.0 and EAB WHDLoad Games Menu v3.0.0. 
7. When HstWB Installer is complete, replace emulator config1 with
   hstwb-68020-25mhz config file. This is done by pressing F12, 
   click Configurations, click "hstwb-68020-25mhz", click Load,
   click "config1" and click "Save".