# Amibian support files

Following Amibian support files must be installed to aid configuring and running HstWB Installer on Amibian:

- `home`: Script files for home directory installed in Amibian directory `/root`.  
- `amiberry`: Config files for Amiberry installed in Amibian directory `/root/amibian/amiberry/conf`.
- `chips_uae4arm`: Config files for Chip's UAE4ARM installed in Amibian directory `/root/amibian/chips_uae4arm/conf`.

# Updating Amibian image using Ubuntu

Show disk and partition details for image:
```
sudo fdisk -lu amibian1.4.1001_hstwb.img
```

Calculate offset: sector size * start
Example: 512 * 125056 = 64028672

Mount partition as loop with calculation of partition offset (sector size * start, e.g. 512 * 125056):
```
sudo losetup -o $((512*125056)) /dev/loop0 amibian1.4.1001_hstwb.img
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

Unmount partition:
```
sudo umount /mnt/disk
sudo losetup --detach /dev/loop0
```