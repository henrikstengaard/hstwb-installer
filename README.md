# HstWB Installer

## Description

HstWB Installer is a set of powershell scripts, image templates, configuration files, 
AmigaDOS scripts and binaries used to easily build Amiga HDF or directory images with 
automated installation of Workbench, Kickstarts roms and packages with additional content.

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
    [HstWB Installer]
    HstWBInstallerDir=DH1:HstWBInstaller
    SystemDir=DH0:
    [EAB WHDLoad Games AGA Menu]
    WHDLOADDIR=DH1:

The "HstWB Installer" section is required and defines the following:

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

Following image templates included to build new images:

1. 4GB: HDF RDB, DH0 (100MB/PFS3), DH1 (3500MB/PFS3)
2. 4GB: HDF RDB, DH0 (300MB/PFS3), DH1 (3300MB/PFS3)
3. 8GB: HDF RDB, DH0 (100MB/PFS3), DH1 (7200MB/PFS3)
4. 8GB: HDF RDB, DH0 (300MB/PFS3), DH1 (7000MB/PFS3)
5. 16GB: HDF RDB, DH0 (300MB/PFS3), DH1 (13100MB/PFS3)
6. UAE4ARM: DH0 (100MB/FFS/HDF), DH1 (DIR)
7. UAE4ARM: DH0 (300MB/FFS/HDF), DH1 (DIR)

4GB, 8GB and 16GB images are RDB HDF's using PFS3 AIO filesystem by Toni Wilen and are formatted with pfsformat filename size of 107 characters. Partitions are created with HDToolbox and configured with MaxTransfer value 0x1fe00. HDF files for these images are created so they are ~100MB smaller than various CF/SD cards, so they can be written to CF/SD card using eg. Win32DiskImager for use in real Amiga's.

UAE4ARM images doesn't use RDB as UAE4Arm doesn't support it and uses a directory mounted as DH1, so it can contain more than 1-2GB of games and demos. 
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

* BetterWB: An enhancement built for Workbench 3.1 built by Gulliver for low end Amigas restricted to 68000 processors.
* HstWB: An extension of BetterWB with some icons from ClassicWB and buildin support for ACA, Furia and Blizzard accelerator cards with boot selectors and easy configuration.
* EAB WHDLoad Demos AGA Menu: AGS2 and iGame menus generated with screenshot and details for all AGA/OCS demos currently available in English Board Amiga WHDLoad packs with update 2.6 applied.
* EAB WHDLoad Demos OCS Menu: AGS2 and iGame menus generated with screenshot and details for all OCS demos currently available in English Board Amiga WHDLoad packs with update 2.6 applied.
* EAB WHDLoad Games AGA Menu: AGS2 and iGame menus generated with screenshot and details for all AGA/OCS games currently available in English Board Amiga WHDLoad packs with update 2.6 applied.
* EAB WHDLoad Games OCS Menu: AGS2 and iGame menus generated with screenshot and details for all OCS games currently available in English Board Amiga WHDLoad packs with update 2.6 applied.

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
- Build Self Install: Installs scripts, tools and packages in configured image to self install Workbench, Kickstart roms and packages.
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

Running HstWB Installer in install mode does the following in WinUAE:

- Boots from temp install directory added as INSTALL: harddrive.
- Loads commands resident from DF0: required for installation process.
- Installs Workbench 3.1 to SYSTEMDIR: from adf files in INSTALL:, if configured to install Workbench.
- Installs Kickstart roms to SYSTEMDIR:Devs/Kickstarts from rom files in INSTALL:, if configured to install Kickstart.
- Installs packages from temp packages directory added as PACKAGES: harddrive. For each package, required assigns is set before installing a package and removed when package is installed.

When HstWB Installer is done, the image is ready to run in an emulator or on a real Amiga.

### Build self install mode

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

Then packages are installed, if any are installed in the self install image.

When the self install process is done, the image is ready to run in an emulator or on a real Amiga.

### Test mode

Running HstWB Installer in test mode does the following:

- Boots image for testing configured image directory.

## Example 1: Create an image using install mode

This example describes step by step how to create an image using install mode.

Start HstWB Installer Setup.
Type 1 and enter for select image menu.
![setup_main.png](screenshots/setup_main.png?raw=true)

Create a new image.
Type 2 and enter for create image directory from image template menu.
![setup_select_image.png](screenshots/setup_select_image.png?raw=true)

Pick an image template that matches your needs. 
For this example type 3 and enter for '4GB: HDF RDB, DH0 (300MB/PFS3), DH1 (3300MB/PFS3)' image template.
![setup_create_image_template.png](screenshots/setup_create_image_template.png?raw=true)

Select a directory to create new image.
For this example create and select 'C:\Temp\4GB' directory.
![setup_create_select_directory.png](screenshots/setup_create_select_directory.png?raw=true)

Configure packages that will be installed on the image.
For this example type 1 and enter, 6 and enter, 4 and enter, 2 and enter to install packages: BetterWB, HstWB, EAB WHDLoad Games AGA Menu, EAB WHDLoad Demos AGA Menu.
![setup_configure_packages.png](screenshots/setup_configure_packages.png?raw=true)

Run installer to start HstWB Installer Run.
Type 7 end enter.
![setup_run_installer.png](screenshots/setup_run_installer.png?raw=true)

HstWB Installer Run prepares installation and launches WinUAE to start installation process.
![run_launching_winuae.png](screenshots/run_launching_winuae.png?raw=true)

Installation process installing Workbench from adf files, Kickstart roms and packages. 
![winuae_install_start.png](screenshots/winuae_install_start.png?raw=true)

Installation process done. 
![winuae_install_done.png](screenshots/winuae_install_done.png?raw=true)

Image is now ready for use either in emulator or on real Amiga.

## Example 2: Create an image using build self install mode

This example describes step by step how to create an image using build self install mode.

Start HstWB Installer Setup.
Type 1 and enter for select image menu.
![setup_main.png](screenshots/setup_main.png?raw=true)

Create a new image.
Type 2 and enter for create image directory from image template menu.
![setup_select_image.png](screenshots/setup_select_image.png?raw=true)

Pick an image template that matches your needs. 
For this example type 3 and enter for '4GB: HDF RDB, DH0 (300MB/PFS3), DH1 (3300MB/PFS3)' image template.
![setup_create_image_template.png](screenshots/setup_create_image_template.png?raw=true)

Select a directory to create new image.
For this example create and select 'C:\Temp\4GB' directory.
![setup_create_select_directory.png](screenshots/setup_create_select_directory.png?raw=true)

Configure packages that will be installed on the image.
For this example type 1 and enter, 6 and enter, 4 and enter, 2 and enter to install packages: BetterWB, HstWB, EAB WHDLoad Games AGA Menu, EAB WHDLoad Demos AGA Menu.
![setup_configure_packages.png](screenshots/setup_configure_packages.png?raw=true)

Switch install mode to build self install.
Type 6 and enter for configure installer menu.
Type 1 and enter for change installer mode.
Type 2 and enter for build self install mode 
![setup_build_self_install_mode.png](screenshots/setup_build_self_install_mode.png?raw=true)

Run installer to start HstWB Installer Run.
Type 7 end enter.
![setup_build_self_install_run.png](screenshots/setup_build_self_install_run.png?raw=true)

HstWB Installer Run prepares installation and launches WinUAE to start installation process.
![run_build_self_install_launching.png](screenshots/run_build_self_install_launching.png?raw=true)

Installation process installing system files for self install and packages. 
![run_build_self_install_start.png](screenshots/run_build_self_install_start.png?raw=true)

Installation process done.
![run_build_self_install_done.png](screenshots/run_build_self_install_done.png?raw=true)

Image is now ready for self install either in emulator or on real Amiga.

## Example 3: Running self install using test mode 

This example describes step by step how to run self install mode using test mode.

## Example 4: Writing an image to CF/SD card using Win32DiskImager

This example describes step by step how to write an image to a CF/SD card using Win32DiskImager. 

Only RDB images will work, when written to a CF/SD card. If unsure about RDB, use WinUAE to check if HDF is in RDB mode with following steps:

1. Start WinUAE.
2. Click "CD & Hard drives".
3. Click "Add hardfile...".
4. Click "..." next to path and select HDF file.
5. If "RDB mode" button is grayed out and it says "RDSK...@+......." in the textbox grayed out in the middle, then the HDF is in RDB mode.

**Start Win32DiskImager.**
Click folder icon to select HDF file.
![win32diskimager_start.png](screenshots/win32diskimager_start.png?raw=true)

**Select HDF file to write.**
Change file type to "*.*" from the dropdown menu above "Open" button.
Select HDF file to write eg. "C:\Temp\4GB\4gb.hdf".
![win32diskimager_select.png](screenshots/win32diskimager_select.png?raw=true)

**Select device and write**
Select device to write HDF file to from device dropdown menu matching the CF/SD card to write to.
Click "Write" button to start writing image to device.
![win32diskimager_ready.png](screenshots/win32diskimager_ready.png?raw=true)

**Confirm overwriting selected device**
Double check you have selected the correct device to write to as it will overwrite and destroy it's current content.
Click "Yes" to confirm writing to device, if correct device is selected.
![win32diskimager_confirm.png](screenshots/win32diskimager_confirm.png?raw=true)

**Wait for waiting to finish**
HDF file is being written to device, which can take 10-30 minutes depending on USB and CF/SD card performance.
![win32diskimager_writing.png](screenshots/win32diskimager_writing.png?raw=true)

**Write completed**
Writing HDF file to device completed succesfully and Win32DiskImager can be closed.
![win32diskimager_done.png](screenshots/win32diskimager_done.png?raw=true)

Remember to properly remove the device from Windows to avoid corrupting the device, before unplugging it from the computer.

CF/SD card can now be used either in emulator or on real Amiga.

## Example 5: Installing an image on a RaspBerry Pie with RetroPie

This example describes step by step how to install an image on a RaspBerry Pie with RetroPie.