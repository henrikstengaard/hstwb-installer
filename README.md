# HstWB Installer

HstWB Installer is a set of powershell scripts, image templates, configuration files, 
AmigaDOS scripts and binaries used to easily build Amiga HDF or directory images with 
automated installation of Workbench, Kickstarts roms and packages with additional content.
It's currently being developed and maintained by Henrik Nørfjand Stengaard.

Setting up a blank Amiga HDF image with e.g. PFS3, Workbench, Kickstarts roms, WHDLoad games and demos 
installed properly can be a cumbersome task unless you spend a lot of time figuring out how this is done step by step.

This is where HstWB Installer come to aid and can help to automate such installations using WinUAE and should 
be possible for almost anyone to do with very little knowledge about Amiga.

The packages included are BetterWB, HstWB, EAB WHDLoad games and demos menus for both AGA and OCS.
Menu packages has screenshots and details for EAB games and demos WHDLoad packs configured for
Arcade Game Selector 2 and iGame.
These packages can be added to an image configuration and will be installed during HstWB Installer installation process.

In general HstWB Installer is build as a minimalistic as possible using BetterWB and HstWB to
support A500 as a minimum. HstWB is mainly targeted A500, A600, A1200.
The minimalistic approach allows users to customize it further with their own preferences like 
installing eg. MagicWB or Scalos.
 
Since Amiga Workbench and Kickstart roms are licensed property these files can't be included 
as they need to be acquired legally by buying Cloanto Amiga Forever or using grabkick from aminet 
to dump roms from real Amiga's.

*HstWB is short for my name and Workbench (very original, I know).* 

## License

HstWB Installer is licensed under MIT license, see LICENSE.txt file.

## Requirements

The minimum requirements for running and using HstWB Installer are:

* Windows 7, 8, 8.1 or 10.
* Cloanto Amiga Forever installed or dumps of own Workbench adf files and Kickstart rom files located in a directory.
* WinUAE installed.

## Installation

Installation is quite easy and can be done one the following ways: 

* Download msi installer from releases https://github.com/henrikstengaard/hstwb-installer/releases.
* Clone git repository.
* Click 'Download ZIP' and extract files.

Note: Cloning git repository or 'Download ZIP' doesn't include packages and they must be downloaded separately and copied to packages directory.

## Scripts and user interface

HstWB Installer consists of two main scripts:

- HstWB Installer Setup: Setup script to configure settings, assigns and create new images.
- HstWB Installer Run: Run script to execute configuration.

They are written in powershell scripts and user interface is a console and can be started from:

- Start menu: If installed with msi installer.
- Console: Running cmd or powershell files.

## Settings and data files

HstWB Installer uses the following settings files by default stored in users AppData directory "c:\Users\[username]\AppData\Local\HstWB Installer\":

- Settings.ini: Configuration of image.
- Assigns.ini: Configuration of assigns used during installation for install and build self install modes.

It's recommended to use the "HstWB Installer Setup" to configure an image installation as it handles configuration of both settings, assigns and create new images.
For expert users the settings files can be edited manually using Notepad or a similar editor.

Settings.ini example:
###
    [Image]
    ImageDir=C:\Temp\4GB
    [Installer]
    Mode=Install
    [Kickstart]
    InstallKickstart=Yes
    KickstartRomPath=C:\Users\Public\Documents\Amiga Files\Shared\rom
    KickstartRomSet=Kickstart Cloanto Amiga Forever 2016
    [Packages]
    InstallPackages=eab.whdload.games.aga.menu.2.6.2
    [Winuae]
    WinuaePath=C:\Program Files (x86)\WinUAE\winuae.exe
    [Workbench]
    InstallWorkbench=Yes
    WorkbenchAdfPath=C:\Users\Public\Documents\Amiga Files\Shared\adf
    WorkbenchAdfSet=Workbench 3.1 Cloanto Amiga Forever 2016

The parameters in settings.ini file configures with following:

- ImageDir: Path to image directory containing harddrives.uae, hdf files and directories for directory harddrives.
- Mode: [Install|BuildSelfInstall|Test] Configures mode, when running HstWB Installer. 
- InstallKickstart: [YES|NO] Configures if Kickstart roms should be installed.
- KickstartRomPath: Path to directory with Kickstart rom files. Autoconfigured, if Cloanto Amiga Forever is installed.
- KickstartRomSet: Set of Kickstart rom files to identify and use from KickstartRomPath.
- InstallPackages: Comma separated value defining filename of packages to install without .zip extension.
- WinuaePath: Path to WinUAE executable. Autoconfigured, if WinUAE is installed.
- InstallWorkbench: [YES|NO] Configures if Workbench should be installed.
- WorkbenchAdfPath: Path to directory with Workbench adf files. Autoconfigured, if Cloanto Amiga Forever is installed.
- WorkbenchAdfSet: Set of Workbench adf files to identify and use from WorkbenchAdfPath.

Assigns.ini example:
###
    [Global]
    HstWBInstallerDir=DH1:HstWBInstaller
    SystemDir=DH0:
    [EAB WHDLoad Games AGA Menu]
    WHDLOADDIR=DH1:

The "Global" section is required and defines the following:

- SystemDir: Path to Workbench and system files.
- HstWBInstallerDir: Path to HstWB Installer script, tools and packages for build self install mode.

Additionally there's a section for each added package defining paths for it's required assigns.

---

To identify Workbench adf and Kickstart rom files, HstWB Installer uses following csv data files:

- Workbench-adf-hashes.csv: Csv file with MD5 hashes to identify Workbench 3.1 adf files.
- Kickstart-rom-hashes.csv: Csv file with MD5 hashes to identify Kickstart rom files.

Workbench-adf-hashes.csv example:
###
    Name;Set;Md5Hash;DiskName;Filename
    Workbench 3.1 Extras Disk;Workbench 3.1 Cloanto Amiga Forever 2016;c1c673eba985e9ab0888c5762cfa3d8f;;workbench31extras.adf
    Workbench 3.1 Fonts Disk;Workbench 3.1 Cloanto Amiga Forever 2016;6fae8b94bde75497021a044bdbf51abc;;workbench31fonts.adf
    Workbench 3.1 Install Disk;Workbench 3.1 Cloanto Amiga Forever 2016;d6aa4537586bf3f2687f30f8d3099c99;;workbench31install.adf
    Workbench 3.1 Locale Disk;Workbench 3.1 Cloanto Amiga Forever 2016;b53c9ff336e168643b10c4a9cfff4276;;workbench31locale.adf
    Workbench 3.1 Storage Disk;Workbench 3.1 Cloanto Amiga Forever 2016;4fa1401aeb814d3ed138f93c54a5caef;;workbench31storage.adf
    Workbench 3.1 Workbench Disk;Workbench 3.1 Cloanto Amiga Forever 2016;590c42a69675d6970df350e200fe25dc;;workbench31workbench.adf
    Workbench 3.1 Extras Disk;Workbench 3.1 Custom;;Extras3.1;workbench31extras.adf
    Workbench 3.1 Fonts Disk;Workbench 3.1 Custom;;Fonts;workbench31fonts.adf
    Workbench 3.1 Install Disk;Workbench 3.1 Custom;;Install3.1;workbench31install.adf
    Workbench 3.1 Locale Disk;Workbench 3.1 Custom;;Locale;workbench31locale.adf
    Workbench 3.1 Storage Disk;Workbench 3.1 Custom;;Storage3.1;workbench31storage.adf
    Workbench 3.1 Workbench Disk;Workbench 3.1 Custom;;Workbench3.1;workbench31workbench.adf

Name column defines display name.

Set column defines a collection of Workbench files the file is related to. This is used in settings.ini, where WorkbenchAdfSet parameter defines the set of Workbench adf files HstWB Installer will identify and use from directory in WorkbenchAdfPath parameter.

Md5Hash column defines MD5 hash of the Workbench adf file to match. It's recommended to use MD5 hashes as they will give exact matches.

DiskName column defines adf disk name to match. If MD5 hash is not defined, then disk name is used identify the adf file. 
Using disk name support various version of Workbench 3.1 disks from Commodore and Escom.
The disk name method can also identify wrong adf files is they have same name, but that will not be an issue if directory defined in WorkbenchAdfPath parameter only contains Workbenck 3.1 adf files.

Filename column defines the filename the Workbench adf file will be renamed to. HstWB Installer will check if these filename exists and use them when running in install mode.

Kickstart-rom-hashes.csv example:
###
    Name;Set;Md5Hash;Encrypted;Filename
    Kickstart 1.2 (33.180) (A500) Rom;Kickstart Cloanto Amiga Forever 2016;c56ca2a3c644d53e780a7e4dbdc6b699;Yes;kick33180.A500
    Kickstart 1.3 (34.5) (A500) Rom;Kickstart Cloanto Amiga Forever 2016;89160c06ef4f17094382fc09841557a6;Yes;kick34005.A500
    Kickstart 3.1 (40.063) (A600) Rom;Kickstart Cloanto Amiga Forever 2016;c3e114cd3b513dc0377a4f5d149e2dd9;Yes;kick40063.A600
    Kickstart 3.1 (40.068) (A1200) Rom;Kickstart Cloanto Amiga Forever 2016;dc3f5e4698936da34186d596c53681ab;Yes;kick40068.A1200
    Kickstart 3.1 (40.068) (A4000) Rom;Kickstart Cloanto Amiga Forever 2016;8b54c2c5786e9d856ce820476505367d;Yes;kick40068.A4000
    Kickstart 1.2 (33.180) (A500) Rom;Kickstart Custom;85ad74194e87c08904327de1a9443b7a;No;kick33180.A500
    Kickstart 1.3 (34.5) (A500) Rom;Kickstart Custom;82a21c1890cae844b3df741f2762d48d;No;kick34005.A500
    Kickstart 3.1 (40.063) (A600) Rom;Kickstart Custom;e40a5dfb3d017ba8779faba30cbd1c8e;No;kick40063.A600
    Kickstart 3.1 (40.068) (A1200) Rom;Kickstart Custom;646773759326fbac3b2311fd8c8793ee;No;kick40068.A1200
    Kickstart 3.1 (40.068) (A4000) Rom;Kickstart Custom;9bdedde6a4f33555b4a270c8ca53297d;No;kick40068.A4000

Name column defines display name.

Set column defines a collection of Kickstart rom files the file is related to. This is used in settings.ini, where KickstartRomSet parameter defines the set of Kickstart rom files HstWB Installer will identify and use from directory in KickstartRomPath parameter.

Md5Hash column defines MD5 hash of the Kickstart rom file to match.

Encrypted column defined if Kickstart rom file is encrypted or not. If encrypted Kickstart rom files are installed, then HstWB Installer will also copy required rom.key file.

Filename column defines the filename the Kickstart rom file will be renamed to. HstWB Installer will check if these filename exists and use them when running in install mode.

## Image templates

HstWB Installer has following image templates included to build new images:

1. 2GB: HDF RDB, DH0 (100MB/PFS3), DH1 (1700MB/PFS3)
1. 2GB: HDF RDB, DH0 (300MB/PFS3), DH1 (1500MB/PFS3)
1. 4GB: HDF RDB, DH0 (100MB/PFS3), DH1 (3500MB/PFS3)
2. 4GB: HDF RDB, DH0 (300MB/PFS3), DH1 (3300MB/PFS3)
3. 8GB: HDF RDB, DH0 (100MB/PFS3), DH1 (7110MB/PFS3)
4. 8GB: HDF RDB, DH0 (300MB/PFS3), DH1 (6910MB/PFS3)
5. 16GB: HDF RDB, DH0 (500MB/PFS3), DH1 (13GB/PFS3)
5. 32GB: HDF RDB, DH0 (1000MB/PFS3), DH1 (27GB/PFS3)
5. 64GB: HDF RDB, DH0 (1000MB/PFS3), DH1 (55GB/PFS3)
6. UAE4ARM: DH0 (100MB/FFS/HDF), DH1 (DIR)
7. UAE4ARM: DH0 (300MB/FFS/HDF), DH1 (DIR)

2GB, 4GB, 8GB, 16GB, 32GB and 64GB images are RDB HDF's using PFS3 AIO filesystem by Toni Wilen and are formatted with pfsformat filename size of 107 characters. Partitions are created with HDToolbox and configured with MaxTransfer value 0x1fe00. HDF files for these images are created so they are smaller than various CF/SD cards, so they can be written to CF/SD card using eg. Win32DiskImager for use in real Amiga's.

UAE4ARM images doesn't use RDB as UAE4Arm doesn't support it and uses instead a directory mounted as DH1, so it can contain more than 1-2GB of games and demos. 
The limit is then bound to the size of SD card. Using Samba/Windows share eg. "\\retropie\roms\amiga\hstwb\dh1" gives direct access to DH1 partition making it easy to manage content.

---

An image template for HstWB Installer is a zip file containing set of HDF and configuration files, which are used to build a new image.
Image templates are located in "images" directory.

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

The escaped placeholder is needed for quoted paths like:
###
    uaehf0=hdf,rw,DH0:"[$ImageDirEscaped]\\4gb.hdf",0,0,0,512,0,,uae

Own image templates can be created by following the examples above or use files from one of the existing image templates to get started. Configuration of harddrives.uae can directly be copied from a saved WinUAE configuration, just replace directory paths with [$ImageDir] and [$ImageDirEscaped] placeholders. 

## Packages

Following packages are included with HstWB Installer msi installation:

* [BetterWB Package](https://github.com/henrikstengaard/betterwb-package): An enhancement built for Workbench 3.1 by Gulliver for low end Amigas restricted to 68000 processors.
* [HstWB Package](https://github.com/henrikstengaard/hstwb-package): A minimalistic Workbench enhancement by Henrik Nørfjand Stengaard based on BetterWB targeted A500, A600, A1200 using 16 colour screenmode using PAL / NTSC / Non-Interlaced 640x256 display.
* [ClassicWB LITE Package](https://github.com/henrikstengaard/classicwb-lite-package): A feature rich Workbench enhancement by Bloodwych targeted A1200 using 4/8/16 colour screenmode using PAL / NTSC / Non-Interlaced 640x256 display.
* [ClassicWB FULL Package](https://github.com/henrikstengaard/classicwb-full-package): A feature rich Workbench enhancement by Bloodwych targeted A1200 with 4MB memory expansion using 16 colour screenmode using PAL / NTSC / Non-Interlaced 640x256 display.
* [ClassicWB ADV Package](https://github.com/henrikstengaard/classicwb-adv-package): A feature rich Workbench enhancement by Bloodwych targeted A1200 with 4MB memory expansion using 16 colour screenmode using Multisync / Interlaced 640x512 display.
* [ClassicWB ADVSP Package](https://github.com/henrikstengaard/classicwb-advsp-package): A feature rich Workbench enhancement by Bloodwych targeted A1200 with accelerator, memory expansion using Multisync / Interlaced 640x512 display..
* [ClassicWB P96 Package](https://github.com/henrikstengaard/classicwb-p96-package): A feature rich Workbench enhancement by Bloodwych targeted UAE emulator using 16-32bit colour screenmodes and NewIcons.
* [EAB WHDLoad Demos AGA Menu Package](https://github.com/henrikstengaard/eab-whdload-demos-aga-menu-package): AGS2 and iGame menus generated with screenshot and details for all AGA/OCS demos currently available in English Board Amiga WHDLoad packs with update 2.6 applied.
* [EAB WHDLoad Demos OCS Menu Package](https://github.com/henrikstengaard/eab-whdload-demos-ocs-menu-package): AGS2 and iGame menus generated with screenshot and details for all OCS demos currently available in English Board Amiga WHDLoad packs with update 2.6 applied.
* [EAB WHDLoad Games AGA Menu Package](https://github.com/henrikstengaard/eab-whdload-games-aga-menu-package): AGS2 and iGame menus generated with screenshot and details for all AGA/OCS games currently available in English Board Amiga WHDLoad packs with update 2.6 applied.
* [EAB WHDLoad Games OCS Menu Package](https://github.com/henrikstengaard/eab-whdload-games-ocs-menu-package): AGS2 and iGame menus generated with screenshot and details for all OCS games currently available in English Board Amiga WHDLoad packs with update 2.6 applied.

---

An package for HstWB Installer is a zip file containing configuration files, AmigaDOS scripts and resources, which are used to install a package.
Packages are located in "packages" directory.

Each package zip file contains the following files:

- package.ini (Required): Ini file with package details and default assigns.
- install (Required): AmigaDOS script to perform installation of the package.
- other files (Optional): Resource files, which are installed or used during installation.

Before a package installation begins, a set of assigns are added:

- PACKAGEDIR: Path to directory containing the package.
- Assigns for package configured in assigns.ini.

Package.ini example:
###
    [Package]
    Name=EAB WHDLoad Games AGA Menu
    Version=2.6.2
    Dependencies=HstWB
    Assigns=WHDLOADDIR
    [DefaultAssigns]
    WHDLOADDIR=DH1:

Name and version are required parameters.

Dependencies parameter has a comma separated value defining dependencies to other packages. 
If a package doesn't have any dependencies, the dependencies parameter value can be empty or removed.

Assigns parameter has a comma separated value defining required assigns for installing the package. 
These assigns are set before the package is installed and removed when the package is installed.

The default assigns section defines default assign values for the requires assigns. 
These are added to assigns.ini when adding a package and they can be changed later by editing assigns.ini file for customizing installation.

## Installer modes

HstWB Installer supports following installer modes:

- Install: Installs Workbench, Kickstart roms and packages in configured image.
- Build Self Install: Builds install scripts, tools and packages in configured image to self install Workbench, Kickstart roms and packages.
- Build Package Installation: Builds install scripts to install packages only.
- Test: Test configured image.

### Preparing installer run

Before HstWB Installer runs it prepares the files it needs in a temp directory.
For any installer mode HstWB Installer uses WinUAE configuration file "hstwb-installer.uae" in "winuae" directory.
It contains following placeholders used to configure Kickstart rom, DF0: floppy and harddrives:

- [$KICKSTARTROMFILE]: Replaced with path to A1200 Kickstart 3.1 rom file identified in configured kickstart path.
- [$WORKBENCHADFFILE]: Replaced with path to Workbench 3.1 Workbench disk file identified in configured workbench path. This is only used for "Install" and "Build Self Install" installer modes.
- [$HARDDRIVES]: Replaced with harddrives.uae from image directory. For "Install" and "Build Self Install" installer modes directories INSTALL: and PACKAGES: are added containing install scripts, tools and package files to install.  

[$KICKSTARTROMFILE] placeholder example before and after being replaced:
###
    kickstart_rom_file=[$KICKSTARTROMFILE]
    ...
    kickstart_rom_file=c:\Users\Public\Documents\Amiga Files\Shared\rom\amiga-os-310-a1200.rom

[$WORKBENCHADFFILE] placeholder example before and after being replaced:
###
    floppy0=[$WORKBENCHADFFILE]
    ...
    floppy0=c:\Users\Public\Documents\Amiga Files\Shared\adf\amiga-os-310-workbench.adf

[$HARDDRIVES] placeholder example before and after being replaced:
###
    [$HARDDRIVES]
    ...
    hardfile2=rw,DH0:C:\Temp\4GB\4gb.hdf,0,0,0,512,-128,,uae
    uaehf0=hdf,rw,DH0:"C:\\Temp\\4GB\\4gb.hdf",0,0,0,512,-128,,uae
    filesystem2=rw,INSTALL:Install:C:\Users\hst\AppData\Local\Temp\HstWB-Installer_vbb21ubf.ayx\install,6
    uaehf1=dir,rw,INSTALL:Install:C:\Users\hst\AppData\Local\Temp\HstWB-Installer_vbb21ubf.ayx\install,6
    filesystem2=rw,PACKAGES:Packages:C:\Users\hst\AppData\Local\Temp\HstWB-Installer_vbb21ubf.ayx\packages,-128
    uaehf2=dir,rw,PACKAGES:Packages:C:\Users\hst\AppData\Local\Temp\HstWB-Installer_vbb21ubf.ayx\packages,-128

The temp directory will contain WinUAE configuration, startup sequence scripts, tools and extracted packages to install depending on the configuration. 
When HstWB Installer is done the temp directory is deleted.

For "Install" and "Build Self Install" installer modes following additional files are prepared in the temp directory:
- Identifies and copies Kickstart roms files from Kickstart path to temp install directory.  
- Identifies and copies Workbench 3.1 adf files from Workbench path to temp install directory.  
- Extracts packages to temp packages directory.

### Install mode

Install mode can install Workbench, Kickstart roms and configured packages to an image.

Running HstWB Installer in install mode does the following in WinUAE:

- Boots from temp install directory added as INSTALL: harddrive.
- Loads commands resident from DF0: required for installation process.
- Installs Workbench 3.1 to SYSTEMDIR: from adf files in INSTALL:, if configured to install Workbench.
- Installs Kickstart roms to SYSTEMDIR:Devs/Kickstarts from rom files in INSTALL:, if configured to install Kickstart.
- Installs packages from temp packages directory added as PACKAGES: harddrive. For each package, required assigns is set before installing a package and removed when package is installed.

When HstWB Installer is done, the image is ready to run in an emulator or on a real Amiga.

### Build self install mode

Build self install mode builds an image that can install Workbench from floppies or adf, Kickstart roms and configured packages.
A self install image is independent from HstWB Installer and can be run in an emulator or real Amiga with Kickstart 3.1.

Running HstWB Installer in build self install mode does the following:

- Boots from temp install directory added as INSTALL: harddrive.
- Loads commands resident from DF0: required for installation process.
- Copy self install scripts and tools to SYSTEMDIR:.
- Copy system files to HSTWBINSTALLER: from temp install directory added as INSTALL: harddrive.
- Copy package files to HSTWBINSTALLER:Packages from temp packages directory added as PACKAGES: harddrive.

When HstWB Installer is done, the image is ready for self install in an emulator or on a real Amiga.

As self install process requires Workbench 3.1 disk, it will detect which floppy drive DF0:, DF1:, DF2: or DF3: contains Workbench 3.1 Workbench disk.
The detect floppy drive will later be used for installing Workbench from floppies, if needed.

Running a self install image in an emulator can automate installation of Workbench 3.1 and Kickstart roms.
This is done during self install process, which detects if following harddrives are present:

- WORKBENCHDIR: Directory added in emulator with Workbench 3.1 adf files.
- KICKSTARTDIR: Directory added in emulator with Kickstart rom files.

Workbench 3.1 adf files will be identify and used to install Workbench, if WORKBENCHDIR: is present.
If WORKBENCHDIR: is not present or if Workbench 3.1 adf installation fails, the self install process will fallback to install Workbench from floppys.

Kickstart roms will be identified and installed to SYSTEMDIR:Devs/Kickstarts, if KICKSTARTDIR: is present.

For package installation a dialog is presented to select packages to install.
This is useful for building an image with content targeted for multiple Amigas, eg. including both OCS and AGA packages for AGS2. 
AGA packages can be selected for A1200/A4000 and OCS packages can be selected for A500/A600.

When the self install process is done, the image is ready to run in an emulator or on a real Amiga.

### Build package installation mode

Build package installation mode builds install script to install configured packages.
A package installation is independent from HstWB Installer and can be run on any Amiga with Kickstart 3.1, so packages can be installed on existing harddrives.

Running HstWB Installer in build package installation mode does the following:

- Present folder dialog to select directory where to build package installation.
- Build package installation script.
- Copy package files to selected directory.

When build package installation is done, the directory can be added in WinUAE for installation or copied to a real Amiga using CF card, network or USB depending on hardware installed in the Amiga.

Running a package installation presents a dialog to select packages to install.
This is useful as the package installation can be targeted for multiple Amigas, eg. including both OCS and AGA packages for AGS2. 
AGA packages can be selected for A1200/A4000 and OCS packages can be selected for A500/A600.

### Test mode

Test mode can be used to test configured image. It can also be used to run self install to prepare an image for use in an emulator or copying the image to a real Amiga. 

Running HstWB Installer in test mode does the following:

- Boots image for testing configured image directory.

## FAQ

Find questions and answers to commonly asked questions using HstWB Installer and HDF images.

**Q:** I have written a HDF image to a CF card and connected it to the PCMCIA port on my A1200/A600, but it won't boot from CF card?

**A:** A standard A1200/A600 with Kickstart 3.1/3.0/2.05 can't boot a CF card from PCMCIA port. A HDF image written to CF/SD card works on a standard A1200/A600 using a CF/SD to IDE adapter. 

## Tutorials

Tutorials showing how HstWB Installer is used and can be installed.

### Tutorial 1: Create an image using install mode

This tutorial describes step by step how to create an image using install mode.

**1. Start HstWB Installer Setup**

Start HstWB Installer Setup from start menu or powershell.

Type 1 and enter for select image menu.

![build_install_1.png](screenshots/build_install_1.png?raw=true)

**2. Create a new image**

Type 2 and enter for create image directory from image template menu.

![build_install_2.png](screenshots/build_install_2.png?raw=true)

**3. Pick an image template that matches your needs**

For this example type 4 and enter for '4GB: HDF RDB, DH0 (300MB/PFS3), DH1 (3300MB/PFS3)' image template.

**Note: Option numbers depend on the images installed in HstWB Installer "images" directory, so they may vary.**

![build_install_3.png](screenshots/build_install_3.png?raw=true)

**4. Select a directory to create new image**

For this example create and select 'C:\Temp\4GB' directory.

![build_install_4.png](screenshots/build_install_4.png?raw=true)

Press enter to continue when extraction of image files is done.

![build_install_5.png](screenshots/build_install_5.png?raw=true)

Type 3 and enter for back to main menu.

![build_install_6.png](screenshots/build_install_6.png?raw=true)

**5. Configure packages that will be installed on the image**

Type 4 and enter for configure packages menu.

![build_install_7.png](screenshots/build_install_7.png?raw=true)

For this example type 1 and enter, 11 and enter, 9 and enter, 7 and enter to install packages: BetterWB, HstWB, EAB WHDLoad Games AGA Menu, EAB WHDLoad Demos AGA Menu.

**Note: Option numbers depend on the packages installed in HstWB Installer "packages" directory, so they may vary.**

![build_install_8.png](screenshots/build_install_8.png?raw=true)

Type 12 and enter for back to main menu.

![build_install_9.png](screenshots/build_install_9.png?raw=true)

**6. Run installer**

Type 7 end enter to run installer.

![build_install_10.png](screenshots/build_install_10.png?raw=true)

**7. HstWB Installer preparing and launching WinUAE**

HstWB Installer Run prepares files for installation and launches WinUAE to start installation process.

![build_install_11.png](screenshots/build_install_11.png?raw=true)

**8. Installation process running**

Installation process is starting.

![build_install_12.png](screenshots/build_install_12.png?raw=true)

Workbench installation is complete and installation process can be continued by pressing "Enter".

![build_install_13.png](screenshots/build_install_13.png?raw=true)

Kickstart installation is complete and installation process can be continued by pressing "Enter".

![build_install_14.png](screenshots/build_install_14.png?raw=true)

Package installation is complete and installation process can be continued by pressing "Enter".

![build_install_15.png](screenshots/build_install_15.png?raw=true)

Installation process is done and will automatically close WinUAE.

![build_install_16.png](screenshots/build_install_16.png?raw=true)

**9. Installation process done**

Image is now ready for use either in emulator or on real Amiga.

Press enter to continue and it will return to main menu.

![build_install_17.png](screenshots/build_install_17.png?raw=true)

### Tutorial 2: Create an image using build self install mode

This tutorial describes step by step how to create an image using build self install mode.

**1. Start HstWB Installer Setup**

Start HstWB Installer Setup from start menu or powershell.

Type 1 and enter for select image menu.

![build_install_1.png](screenshots/build_install_1.png?raw=true)

**2. Create a new image**

Type 2 and enter for create image directory from image template menu.

![build_install_2.png](screenshots/build_install_2.png?raw=true)

**3. Pick an image template that matches your needs**

For this example type 4 and enter for '4GB: HDF RDB, DH0 (300MB/PFS3), DH1 (3300MB/PFS3)' image template. 
**Note: Option numbers depend on the images installed in HstWB Installer "images" directory, so they may vary.**

![build_install_3.png](screenshots/build_install_3.png?raw=true)

**4. Select a directory to create new image**

For this example create and select 'C:\Temp\4GB' directory.

![build_install_4.png](screenshots/build_install_4.png?raw=true)

Press enter to continue when extraction of image files is done.

![build_install_5.png](screenshots/build_install_5.png?raw=true)

Type 3 and enter for back to main menu.

![build_install_6.png](screenshots/build_install_6.png?raw=true)

**5. Configure packages that will be installed on the image**

Type 4 and enter for configure packages menu.

![build_install_7.png](screenshots/build_install_7.png?raw=true)

For this example type 1 and enter, 11 and enter, 9 and enter, 7 and enter to install packages: BetterWB, HstWB, EAB WHDLoad Games AGA Menu, EAB WHDLoad Demos AGA Menu.
**Note: Option numbers depend on the packages installed in HstWB Installer "packages" directory, so they may vary.**

![build_install_8.png](screenshots/build_install_8.png?raw=true)

Type 12 and enter for back to main menu.

![build_install_9.png](screenshots/build_install_9.png?raw=true)

**6. Switch install mode to build self install**

Type 6 and enter for configure installer menu.

![build_install_10.png](screenshots/build_install_10.png?raw=true)

Type 1 and enter for change installer mode.

![build_self_install_1.png](screenshots/build_self_install_1.png?raw=true)

Type 2 and enter for build self install mode.

![build_self_install_2.png](screenshots/build_self_install_2.png?raw=true)

Type 2 and enter for back to main menu.

![build_self_install_3.png](screenshots/build_self_install_3.png?raw=true)

**7. Run installer**

Type 7 end enter to run installer.

![build_self_install_4.png](screenshots/build_self_install_4.png?raw=true)

**8. HstWB Installer preparing and launching WinUAE**

HstWB Installer Run prepares installation and launches WinUAE to start installation process.

![build_self_install_5.png](screenshots/build_self_install_5.png?raw=true)

**9. Installation process running**

Installation process installing system files for self install and packages. 

![build_self_install_6.png](screenshots/build_self_install_6.png?raw=true)

Installation process is done and will automatically close WinUAE after 10 seconds.

![build_self_install_7.png](screenshots/build_self_install_7.png?raw=true)

**10. Installation process done**

Image is now ready for self install in an emulator or on real Amiga.

Press enter to continue and it will return to main menu.

![build_self_install_8.png](screenshots/build_self_install_8.png?raw=true)

### Tutorial 3: Running self install in an emulator or on real Amiga

This tutorial describes step by step how to run self install in an emulator or on real Amiga.

Self install can be run in following ways:

1. HstWB Installer Setup: Switch to test mode and run installer.
2. WinUAE: Start WinUAE using an A1200 configuration with HDF files and/or directories added.
3. UAE4ARM: Start UAE4ARM using an A1200 configuration with HDF files and/or directories added.
4. Real Amiga: Use 'Writing an image to CF/SD card using Win32DiskImager' tutorial and skip automated installation, which is only for emulators.

**Note: Running self install HDF images in emulator or on real Amiga requires Kickstart 3.1. Kickstart 3.0 will also work, but results in some errors removing assigns, which prevents self install to remove DH1:HstWBInstaller drawer using during installation process. It can be removed manually after completing self install.**

#### Configuring emulator for automated installation of Workbench and Kickstart roms

Installation of Workbench and Kickstart roms can be automated, when running self install in an emulator.

To automate installation of Workbench, add a harddrive as directory in the emulator containing Workbench adf files.
The harddrive directory must have device name "WORKBENCHDIR" without quotes.
Users with Cloanto Amiga Forever installed can use the directory "c:\Users\Public\Documents\Amiga Files\Shared\adf", which contains Workbench 3.1 adf files self install will identify and use.

To automate installation of Kickstart roms for WHDLoad, add a harddrive as directory in the emulator containing Kickstart rom files.
The harddrive directory must have device name "KICKSTARTDIR" without quotes.
Users with Cloanto Amiga Forever installed can use the directory "c:\Users\Public\Documents\Amiga Files\Shared\rom", which contains Kickstart rom files self install will identify and use.

The example below describes how to do configure WinUAE for automated installation, but can be done with other emulators like FS-UAE or UAE4ARM adding harddrive directories with correct device names "WORKBENCHDIR" and "KICKSTARTDIR".

**1. Start WinUAE**

Configure harddrive directories for WinUAE in following ways:

1. Using HstWB Installer test mode press F12 after WinUAE is launched to configure harddrive directories.
2. Manually start WinUAE and use own configuration with image HDF files and/or harddrive directories added.

**2. Configure harddrive directories**

Click "CD & Hard drives".

![self_install_winuae_harddrives_start.png](screenshots/self_install_winuae_harddrives_start.png?raw=true)

**3. Add WORKBENCHDIR harddrive directory**

Click "Add Directory or Archive".

Enter "WORKBENCHDIR" in device name and volume label textboxes.

Uncheck "Read/Write" and "Bootable" checkboxes.

Click "Select Directory" and select directory "c:\Users\Public\Documents\Amiga Files\Shared\adf".

Click "OK" to add the directory as a harddrive.

![self_install_winuae_workbenchdir.png](screenshots/self_install_winuae_workbenchdir.png?raw=true)

**4. Add KICKSTARTDIR harddrive directory**

Click "Add Directory or Archive".

Enter "KICKSTARTDIR" in device name and volume label textboxes.

Uncheck "Read/Write" and "Bootable" checkboxes.

Click "Select Directory" and select directory "c:\Users\Public\Documents\Amiga Files\Shared\rom".

Click "OK" to add the directory as a harddrive.

![self_install_winuae_kickstartdir.png](screenshots/self_install_winuae_kickstartdir.png?raw=true)

**5. Verify configured harddrives**

Verify WinUAE has image HDF files and/or directories added together with "WORKBENCHDIR" and "KICKSTARTDIR" directory harddrives.

![self_install_winuae_harddrives_done.png](screenshots/self_install_winuae_harddrives_done.png?raw=true)

**6. Reset WinUAE**

Click "Reset" to reset emulator, which will make self install detect added harddrive directories for automated installation.

#### Running self install

**1. Start self install**.

Start self install image either an emulator or on real Amiga.

![run_self_install_1.png](screenshots/run_self_install_1.png?raw=true)

**2. Insert Workbench 3.1 disk**

Installation process will automatically detect and use DF0:, DF1:, DF2: or DF3: containing required Workbench 3.1 disk.

Insert required Workbench 3.1 disk in any floppy device and press enter to continue installation process.

![run_self_install_2.png](screenshots/run_self_install_2.png?raw=true)

![run_self_install_3.png](screenshots/run_self_install_3.png?raw=true)

**3. Patch installation**

Patch installation will check if device name PATCHDIR: is present and use it to patch the installation.

If device name PATCHDIR: is present, it will copy Workbench.library from PATCHDIR: to SYS:Libs to add support for A4000T systems.

For this example device name PATCHDIR: is not present and patch installation is skipped.

Press enter to continue installation process.

![run_self_install_4.png](screenshots/run_self_install_4.png?raw=true)

**4. Automate installation**

Automate installation shows automation status.

For this example both device name WORKBENCHDIR: and KICKSTARTDIR: are present and will be used to detect and install Workbench and Kickstart roms.

Press enter to continue installation process.

![run_self_install_5.png](screenshots/run_self_install_5.png?raw=true)

**5. Workbench installation**

For this example device name WORKBENCHDIR: is present and is used to detect and install Workbench from adf files.

Press enter to continue installation process.

![run_self_install_6.png](screenshots/run_self_install_6.png?raw=true)

**6. Kickstart installation**

For this example device name KICKSTARTDIR: is present and is used to detect and install Kickstart roms files.

Press enter to continue installation process.

![run_self_install_7.png](screenshots/run_self_install_7.png?raw=true)

**7. Eject disk**

Eject Workbench 3.1 disk and press enter to continue installation process.

![run_self_install_8.png](screenshots/run_self_install_8.png?raw=true)

**8. Workbench installation complete and reboot**

Workbench and Kickstart installation is complete. 

Press enter to continue reboot and start package installation.

![run_self_install_9.png](screenshots/run_self_install_9.png?raw=true)

**9. Select packages to install**

Select packages to install shows a list of packages that are included in the package installation.

Click on a package to select if it will be installed or not, which is indicated with YES or NO next to the package.

![run_self_install_10.png](screenshots/run_self_install_10.png?raw=true)

For this example click on packages BetterWB, HstWB, EAB WHDLoad Games AGA Menu and EAB WHDLoad Demos AGA Menu to switch them to YES, so they will be installed.

**Note: Only one Workbench system package should be installed, so choose to install either BetterWB, BetterWB + HstWB or a ClassicWB package.**

![run_self_install_11.png](screenshots/run_self_install_11.png?raw=true)

**10. View readme**

Click "View Readme" to view readme for packages that are included in the package installation.

This is optional and can be skipped.

![run_self_install_11.png](screenshots/run_self_install_11.png?raw=true)

Click on a package to view it's readme.

For example EAB WHDLoad Games AGA Menu is clicked showing it's Amiga guide readme description and screenshots.

![run_self_install_12.png](screenshots/run_self_install_12.png?raw=true)

![run_self_install_13.png](screenshots/run_self_install_13.png?raw=true)

![run_self_install_14.png](screenshots/run_self_install_14.png?raw=true)

![run_self_install_15.png](screenshots/run_self_install_15.png?raw=true)

**11. Edit assigns**

Click "Edit assigns" to change assigns each package uses during package installation.

This is optional and can be skipped.

![run_self_install_11.png](screenshots/run_self_install_11.png?raw=true)

Edit assigns shows packages and the assigns each package uses during package installation.

Click on any assigns (ending with :) to edit them and change drawer the package will install it's content to.

![run_self_install_16.png](screenshots/run_self_install_16.png?raw=true)

![run_self_install_17.png](screenshots/run_self_install_17.png?raw=true)

**12. Ready to install packages**

Click "Install packages", when packages to install are selected and assigns have been edited (if needed).

![run_self_install_11.png](screenshots/run_self_install_11.png?raw=true)

**13. Confirm package installation**

Click "Yes" to confirm selected packages will be installed.

![run_self_install_18.png](screenshots/run_self_install_18.png?raw=true)

**14. Package installation running**

Package installation running showing progress if each package being installed.

![run_self_install_19.png](screenshots/run_self_install_19.png?raw=true)

**15. Package installation done**

Selected package are installed and package installation is done.

Press enter to continue, which will continue package installation.

![run_self_install_20.png](screenshots/run_self_install_20.png?raw=true)

**16. Installation cleanup**

Packages and temp files used for installation process are deleted.

![run_self_install_21.png](screenshots/run_self_install_21.png?raw=true)

**17. Package installation complete and reboot**

Package installation is complete and the system is ready to use. It will wait 10 seconds to allow the system to write changes to the disk.

Press enter to continue system reboot in 10 seconds.

![run_self_install_22.png](screenshots/run_self_install_22.png?raw=true)

### Tutorial 4: Create a package installation using build package installation mode

This tutorial describes step by step how to build a package installation using build package installation mode.

**1. Start HstWB Installer Setup**

Start HstWB Installer Setup from start menu or powershell.

Type 4 and enter for configure packages menu.

![build_package_installation_1.png](screenshots/build_package_installation_1.png?raw=true)

**2. Configure packages that will be installed in package installation**

For this example type 7 and enter, 8 and enter, 9 and enter, 10 and enter to install packages: EAB WHDLoad Demos AGA Menu, EAB WHDLoad Demos OCS Menu, EAB WHDLoad Games AGA Menu, EAB WHDLoad Games OCS Menu. 

**Note: Option numbers depend on the packages installed in HstWB Installer "packages" directory, so they may vary.**

![build_package_installation_2.png](screenshots/build_package_installation_2.png?raw=true)

Type 12 and enter for back to main menu.

![build_package_installation_3.png](screenshots/build_package_installation_3.png?raw=true)

**3. Switch install mode to build package installation**

Type 6 and enter for configure installer menu.

![build_package_installation_4.png](screenshots/build_package_installation_4.png?raw=true)

Type 1 and enter for change installer mode.

![build_package_installation_5.png](screenshots/build_package_installation_5.png?raw=true)

Type 3 and enter for build package installation mode. 

![build_package_installation_6.png](screenshots/build_package_installation_6.png?raw=true)

Type 2 and enter for back to main menu.

![build_package_installation_7.png](screenshots/build_package_installation_7.png?raw=true)

**4. Run installer**

Type 7 end enter to run installer.

![build_package_installation_8.png](screenshots/build_package_installation_8.png?raw=true)

**5. Select a directory for building package installation**

For this example create and select 'C:\Temp\Package Installation' directory.

![build_package_installation_9.png](screenshots/build_package_installation_9.png?raw=true)

**6. Installer done**

Package installation is now ready for use either in emulator or on real Amiga.

![build_package_installation_10.png](screenshots/build_package_installation_10.png?raw=true)

### Tutorial 5: Running package installation in an emulator or on real Amiga

This tutorial describes step by step how to run package installation in an emulator or on real Amiga.

Package installation can be run in following ways:

1. HstWB Installer Setup: Switch to test mode and run installer.
2. Manually using an emulator: Start WinUAE, FS-UAE, UAE4ARM or other Amiga emulator with HDF files and/or directories added.
3. Real Amiga: Copy package installation to FAT-32 formatted CF-card and insert into Amiga using PCMCIA adapter.

#### Configuring emulator for package installation

Package installation can be run using an emulator by adding directory containing package installation.

**1. Start WinUAE**

Configure harddrive directories for WinUAE in following ways:

1. Using HstWB Installer test mode press F12 after WinUAE is launched to configure harddrive directories.
2. Manually start WinUAE and use own configuration with image HDF files and/or harddrive directories added.

**2. Configure harddrive directories**

Click "CD & Hard drives".

![run_package_installation_1.png](screenshots/run_package_installation_1.png?raw=true)

**3. Add PC harddrive directory**

Click "Add Directory or Archive".

Enter "PC" in device name and volume label textboxes.

Uncheck "Read/Write" and "Bootable" checkboxes.

Click "Select Directory" and select directory "c:\Temp\Package Installation".

Click "OK" to add the directory as a harddrive.

![run_package_installation_2.png](screenshots/run_package_installation_2.png?raw=true)

**4. Verify configured harddrives**

Verify WinUAE has image HDF files and/or directories added together with "PC" directory harddrive.

![run_package_installation_3.png](screenshots/run_package_installation_3.png?raw=true)

**5. Reset WinUAE**

Click "Reset" to reset emulator and PC harddrive is available in Workbench.

**6. Open PC harddrive**

Open PC harddrive with double-click and package installation can be started. 

![run_package_installation_4.png](screenshots/run_package_installation_4.png?raw=true)

#### Running package installation

**1. Start package installation**.

Double-click "Package Installation" icon to start package installation.

![run_package_installation_4.png](screenshots/run_package_installation_4.png?raw=true)

**2. Select packages to install**

Select packages to install shows a list of packages that are included in the package installation.

Click on a package to select if it will be installed or not, which is indicated with YES or NO next to the package.

![run_package_installation_5.png](screenshots/run_package_installation_5.png?raw=true)

For this example click on package EAB WHDLoad Games AGA Menu to switch it to YES, so it will be installed.

![run_package_installation_10.png](screenshots/run_package_installation_10.png?raw=true)

**3. View readme**

Click "View Readme" to view readme for packages that are included in the package installation.

This is optional and can be skipped.

![run_package_installation_10.png](screenshots/run_package_installation_10.png?raw=true)

Click on a package to view it's readme.

For example EAB WHDLoad Games AGA Menu is clicked showing it's Amiga guide readme description and screenshots.

![run_package_installation_6.png](screenshots/run_package_installation_6.png?raw=true)

![run_package_installation_7.png](screenshots/run_package_installation_7.png?raw=true)

![run_package_installation_8.png](screenshots/run_package_installation_8.png?raw=true)

![run_package_installation_9.png](screenshots/run_package_installation_9.png?raw=true)

**4. Edit assigns**

Click "Edit assigns" to change assigns each package uses during package installation.

This is optional and can be skipped.

![run_package_installation_10.png](screenshots/run_package_installation_10.png?raw=true)

Edit assigns shows packages and the assigns each package uses during package installation.

Click on any assigns (ending with :) to edit them and change drawer the package will install it's content to.

![run_package_installation_11.png](screenshots/run_package_installation_11.png?raw=true)

![run_package_installation_12.png](screenshots/run_package_installation_12.png?raw=true)

**5. Ready to install packages**

Click "Install packages", when packages to install are selected and assigns have been edited (if needed).

![run_package_installation_10.png](screenshots/run_package_installation_10.png?raw=true)

**6. Confirm package installation**

Click "Yes" to confirm selected packages will be installed.

![run_package_installation_13.png](screenshots/run_package_installation_13.png?raw=true)

**7. Package installation running**

Package installation running showing progress if each package being installed.

![run_package_installation_14.png](screenshots/run_package_installation_14.png?raw=true)

**8. Package installation done**

Selected package are installed and package installation is done.

Press enter to continue, which will end and close package installation.

![run_package_installation_15.png](screenshots/run_package_installation_15.png?raw=true)

### Tutorial 6: Writing a HDF image to CF/SD card using Win32DiskImager

This tutorial describes step by step how to write an HDF image to a CF/SD card using Win32DiskImager, which can be connected to eg. A1200 or A600 internal IDE port using a CF/SD to IDE adapter.

Only RDB images will work, when written to a CF/SD card. If unsure about RDB, use WinUAE to check if HDF is in RDB mode with following steps:

1. Start WinUAE.
2. Click "CD & Hard drives".
3. Click "Add hardfile...".
4. Click "..." next to path and select HDF file.
5. If "RDB mode" button is grayed out and it says "RDSK...@+......." in the textbox grayed out in the middle, then the HDF is in RDB mode.

![winuae_hdf_rdb_mode.png](screenshots/winuae_hdf_rdb_mode.png?raw=true)

If HDF is in RDB mode, then proceed.

**1. Start Win32DiskImager.**

Click folder icon to select HDF file.

![win32diskimager_start.png](screenshots/win32diskimager_start.png?raw=true)

**2. Select HDF file to write.**

Change file type to "\*.\*" from the dropdown menu above "Open" button.

Select HDF file to write eg. "C:\Temp\4GB\4gb.hdf".

![win32diskimager_select.png](screenshots/win32diskimager_select.png?raw=true)

**3. Select device and write**

Select device to write HDF file to from device dropdown menu matching the CF/SD card to write to.

Click "Write" button to start writing image to device.

![win32diskimager_ready.png](screenshots/win32diskimager_ready.png?raw=true)

**4. Confirm overwriting selected device**

Double check you have selected the correct device to write to as it will overwrite and destroy it's current content.

Click "Yes" to confirm writing to device, if correct device is selected.

![win32diskimager_confirm.png](screenshots/win32diskimager_confirm.png?raw=true)

**5. Wait for write to finish**

HDF file is being written to device, which can take 10-30 minutes depending on USB and CF/SD card performance.

![win32diskimager_writing.png](screenshots/win32diskimager_writing.png?raw=true)

**6. Write completed**

Writing HDF file to device completed succesfully and Win32DiskImager can be closed.

![win32diskimager_done.png](screenshots/win32diskimager_done.png?raw=true)

Remember to properly remove the device from Windows to avoid corrupting the device, before unplugging it from the computer.

CF/SD card can now be used either in emulator or on real Amiga.

### Tutorial 7: Installing an image on a RaspBerry Pie with Retro Pie

This tutorial describes step by step how to install an image on a RaspBerry Pie with Retro Pie.

When connecting Retro Pie use default credentials for Shell and Samba/Windows share access:
###
	Username: pi
	Password: raspberry

**1. Install Kickstart rom**

UAE4ARM needs a Kickstart rom in order to run. 
Since Amiga Kickstart roms are still under license and sold commercially, they can either be bought from Amiga Forever or dumped from own real Amiga using a tool like GrabKick [http://aminet.net/package/util/misc/GrabKick](http://aminet.net/package/util/misc/GrabKick).

Image HDF files and directories created by HstWB Installer are mainly target Kickstart 3.1 rom.

Install A1200 Kickstart 3.1 rom on Retro Pie with following steps:

1. Find own A1200 Kickstart 3.1 rom and rename it to "kick31.rom".
2. Select "kick31.rom" and press CTRL+C to copy it.
3. Enter "\\RETROPIE\bios" in Windows Explorer path field.
4. Type default Retro Pie credentials, if required.
5. Press CTRL+V to paste files.
6. Close Windows Explorer window.

**2. Copy UAE4ARM image HDF files and directories**

Copy UAE4ARM image HDF files and directories to Retro Pie with following steps:

1. Start Windows Explorer.
2. Open image directory by enter eg. "C:\Temp\4GB" in Windows Explorer path field.
3. Press CTRL+A to select all files and press CTRL+C to copy them.
4. Enter "\\RETROPIE\roms\amiga" in Windows Explorer path field.
5. Click-right and select "New folder"
6. Enter "hstwb" for new folder name.
7. Press CTRL+V to paste files.
8. Close Windows Explorer window.

**3. Copy UAE4ARM uae configuration files**

1. Start HstWB Installer Support from start menu.
2. Enter "Retro Pie" and "roms" folder.
3. Select all "HstWB 68020*.uae" files and press CTRL+C to copy them.
4. Enter "\\RETROPIE\configs\amiga" in Windows Explorer path field.
5. Type default Retro Pie credentials, if required.
6. Press CTRL+V to paste files.
7. Close Windows Explorer window.

### Tutorial 8: Modify Retro Pie EmulationStation to show .uae files as roms

This tutorial describes step by step how to modify Retro Pie EmulationStation to show .uae files as roms.

The purpose of making this change is to launch different uae configurations directly from EmulationStation.
Each uae configuration can be configured to run either a set of .adf or .hdf files.

HstWB Installer Support contains uae configuration files, that are configured to use kick31.rom kickstart rom, UAE4ARM hdf and directory harddrives. 
These are also configured to not show gui and will immediately boot.

When connecting Retro Pie use default credentials for Shell and Samba/Windows share access:
###
	Username: pi
	Password: raspberry

#### Copy roms and configs files to Retro Pie using Windows Explorer:

Copy roms files with following steps:

1. Start HstWB Installer Support from start menu.
2. Enter "Retro Pie" and "roms" folder.
3. Press CTRL+A to select all files and press CTRL+C to copy them.
4. Enter "\\RETROPIE\roms\amiga" in Windows Explorer path field.
5. Type default Retro Pie credentials, if required.
6. Press CTRL+V to paste files.
7. Close Windows Explorer window.

Copy configs files with following steps:

1. Start HstWB Installer Support from start menu.
2. Enter "Retro Pie" and "configs" folder.
3. Press CTRL+A to select all files and press CTRL+C to copy them.
4. Enter "\\RETROPIE\configs\amiga" in Windows Explorer path field.
5. Type default Retro Pie credentials, if required.
6. Press CTRL+V to paste files.
7. Close Windows Explorer window.

#### Method 1: Add UAE extensions using Retro Pie File Manager

**1. Start File Manager**

Enter Retro Pie menu in EmulationStation.

Start File Manager.

![retropie_uae_extensions_filemanager1.jpg](screenshots/retropie_uae_extensions_filemanager1.jpg?raw=true)

**2. Hide panels**

Press CTRL+O to hide panels for shell use.

![retropie_uae_extensions_filemanager2.jpg](screenshots/retropie_uae_extensions_filemanager2.jpg?raw=true)

**3. Run add uae extensions bash script**

Type following command to run add uae extensions bash script:
###
    sudo bash /home/pi/RetroPie/roms/amiga/add_uae_extensions.sh

Bash script Successfully added uae extensions, if it returns following output:
###
    UAE extensions successfully added to EmulationStation configuration.

![retropie_uae_extensions_filemanager3.jpg](screenshots/retropie_uae_extensions_filemanager3.jpg?raw=true)

**4. Delete add uae extensions bash script**

Type following command to delete add uae extensions bash script:
###
    sudo rm -f /home/pi/RetroPie/roms/amiga/add_uae_extensions.sh

Press F10 and enter to exit File Manager.

![retropie_uae_extensions_filemanager4.jpg](screenshots/retropie_uae_extensions_filemanager4.jpg?raw=true)

#### Method 2: Add UAE extensions using Putty

**1. Start Putty**

Start Putty.

Enter "retropie" in host name and click "Open".

![retropie_uae_extensions_putty1.png](screenshots/retropie_uae_extensions_putty1.png?raw=true)

**2. Login**

Type default Retro Pie credentials to login.

![retropie_uae_extensions_putty2.png](screenshots/retropie_uae_extensions_putty2.png?raw=true)

**3. Run add uae extensions bash script**

Type following command to run add uae extensions bash script:
###
    sudo bash /home/pi/RetroPie/roms/amiga/add_uae_extensions.sh

Bash script Successfully added uae extensions, if it returns following output:
###
    UAE extensions successfully added to EmulationStation configuration.

![retropie_uae_extensions_putty3.png](screenshots/retropie_uae_extensions_putty3.png?raw=true)

**4. Delete add uae extensions bash script**

Type following command to delete add uae extensions bash script:
###
    sudo rm -f /home/pi/RetroPie/roms/amiga/add_uae_extensions.sh

Press CTRL+D to quit Putty.

![retropie_uae_extensions_putty4.png](screenshots/retropie_uae_extensions_putty4.png?raw=true)