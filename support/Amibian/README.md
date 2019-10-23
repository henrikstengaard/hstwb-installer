# Amibian support files

Following Amibian support files must be installed to aid configuring and running HstWB Installer on Amibian:

- `home`: Script files for home directory installed in Amibian directory `/root`.  
- `amiberry`: Config files for Amiberry installed in Amibian directory `/root/amibian/amiberry/conf`.
- `chips_uae4arm`: Config files for Chip's UAE4ARM installed in Amibian directory `/root/amibian/chips_uae4arm/conf`.

# Updating Amibian image using Ubuntu

Show disk and partition details for image:
```
sudo fdisk -lu /tmp/amibian.img
```

Output
```
Disk /tmp/amibian.img: 3.7 GiB, 4000000000 bytes, 7812500 sectors
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disklabel type: dos
Disk identifier: 0x58cb693c

Device                Boot  Start     End Sectors  Size Id Type
/tmp/amibian.img.img1          16  125055  125040 61.1M  e W95 FAT16 (LBA)
/tmp/amibian.img.img2      125056 7909375 7784320  3.7G 83 Linux
```

Calculate offset: sector size * partition start offset
Example: 512 * 125056 = 64028672

Mount partition as loop with calculation of partition offset (sector size * start, e.g. 512 * 125056):
```
sudo losetup -o $((512*125056)) -f /tmp/amibian.img
```

List all loop devices
```
losetup -a
```

Check partition:
```
sudo e2fsck /dev/loop0
```

Fix partition size:
```
sudo resize2fs /dev/loop0
```

Mount partition as disk:
```
if [ ! -d /mnt/disk ]; then sudo mkdir /mnt/disk; fi
sudo mount /dev/loop0 /mnt/disk
```

# Install HstWB Installer

Copy uae4arm to mounted disk

```
sudo rm -Rf /mnt/disk/root/amibian/amiga_files/hdd/dh1
sudo rm /mnt/disk/root/amibian/amiga_files/hdd/dh0.hdf
sudo rm /mnt/disk/root/amibian/amiga_files/hdd/pfs3aio

sudo cp dh0.hdf /mnt/disk/root/amibian/amiga_files/hdd
sudo cp pfs3aio /mnt/disk/root/amibian/amiga_files/hdd
sudo cp -R dh1 /mnt/disk/root/amibian/amiga_files/hdd
```

Unmount partition:
```
sudo umount /mnt/disk
sudo losetup --detach /dev/loop0
```