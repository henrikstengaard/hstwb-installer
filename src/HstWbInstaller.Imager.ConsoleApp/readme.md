# HstWB Installer Imager

HstWB Installer Imager is an imaging tool to read and write raw disk images to and from physical drives with support for Amiga rigid disk block (RDSK, partition table used by Amiga computers).
This is useful for creating images on modern computers and write them to physical drives such as hard disks, SSD, CF- and MicroSD-cards or creating images of physical drives for backup or tweaking with Amiga emulators much faster than real Amiga hardware.  

## Features

HstWB Installer Imager comes with following features:
- List physical drives (*).
- Display information about physical drive or image file (*).
- Read physical drive to image file (*).
- Write image file to physical drive (*).
- Convert image file between .img/.hdf and .vhd.
- Create blank .img/.hdf and .vhd image file.
- Optimize image file.

(*) requires administrative rights on Windows and Linux.

## Supported operating systems

HstWB Installer Imager supports following operating systems:
- Windows 
- Linux

## Amiga rigid disk block support

HstWB Installer Imager supports Amiga rigid disk block by reading first 16 blocks (512 bytes * 16) from source physical drive or image file.
When creating an image file from a physical drive, HstWB Installer Imager uses Amiga rigid disk block to define the size of the image file to create.
E.g. if a 120GB SSD contains a 16GB Amiga rigid disk block, HstWB Installer Imager will only read the 16GB used and not the entire 120GB.

## Img file format

Img file format is a raw dumps of hard disks, SSD, CF- and MicroSD-cards and consists of a sector-by-sector binary copy of the source.

Creating an .img image file from a 64GB CF-card using HstWB Installer Imager will require 64GB of free disk space on the specified destination path.

## Vhd file format

Vhd file format is a virtual hard disk drive with fixed and dynamic sizes.

Fixed sized vhd file pre-allocates the requested size when created same way as .img file format.

Dynamic sized vhd file only allocates storage to store actual data. Unused or zero filled parts of vhd file are not allocated resulting in smaller image files compared to img image files.

Creating a dynamic sized vhd image file from a 64GB CF-card using HstWB Installer Imager will only require free disk space on the specified destination path matching disk space used on source physical drive.

## Amiga emulators with vhd support

Following Amiga emulators support .vhd image files:
- WinUAE 4.9.0: https://www.winuae.net/
- FS-UAE v3.1.66: https://fs-uae.net/

FS-UAE might require following custom option to force RDB mode by manually changing FS-UAE configuration file (replace 0 with other hard drive number if needed):
```
hard_drive_0_type = rdb
```

## Usage

### List physical drives

Example of listing physical drives:
```
hstwb-installer.imager.exe -l
```

### Display information about a physical drive or image file

Example of display information about a Windows physical drives:
```
hstwb-installer.imager.exe -i \\.\PHYSICALDRIVE2
```

Example of display information about a Linux physical drives:
```
hstwb-installer.imager.exe -i /dev/sdb
```

Example of display information about an image file:
```
hstwb-installer.imager.exe -i 4gb.vhd
```

### Read physical drive to image file

Example of reading Windows physical drive to 4gb.vhd image file:
```
hstwb-installer.imager.exe -r \\.\PHYSICALDRIVE2 4gb.vhd
```

Example of reading Linux physical drive to 4gb.vhd image file:
```
hstwb-installer.imager.exe -r /dev/sdb 4gb.vhd
```

### Write image file to physical drive 

Example of writing 4GB vhd image file to Windows physical drive:
```
hstwb-installer.imager.exe -w 4gb.vhd \\.\PHYSICALDRIVE2
```

Example of writing 4GB vhd image file to Linux physical drive:
```
hstwb-installer.imager.exe -w 4gb.vhd /dev/sdb
```

### Convert an image file

Example of converting 4GB img image file to vhd image file:
```
hstwb-installer.imager.exe -c 4gb.img 4gb.vhd
```

Example of converting 4GB vhd image file to img image file:
```
hstwb-installer.imager.exe -c 4gb.vhd 4gb.img
```

### Create a blank image file

Example of creating a blank 4GB vhd image file:
```
hstwb-installer.imager.exe -b 4gb.vhd -s 4gb
```

Example of creating a blank 4GB img image file:
```
hstwb-installer.imager.exe -b 4gb.img -s 4gb
```

### Optimizing an image file

Example of optimizing a 4GB img image file:
```
hstwb-installer.imager.exe -o 4gb.img 4gb_optimized.img
```

## References

References used for creating HstWB Installer Imager:

- http://csharphelper.com/blog/2017/10/get-hard-drive-serial-number-c/
- https://stackoverflow.com/questions/16679331/createfile-in-kernel32-dll-returns-an-invalid-handle
- https://github.com/t00/TestCrypt/blob/master/TestCrypt/PhysicalDrive.cs
- https://stackoverflow.com/questions/327718/how-to-list-physical-disks
- https://blog.codeinside.eu/2019/09/30/enforce-administrator-mode-for-builded-dotnet-exe/