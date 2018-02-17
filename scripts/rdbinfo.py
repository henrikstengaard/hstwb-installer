#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
# RDB Info
# Author: Henrik Noerfjand Stengaard
# Date: 2018-02-17
#
# A python script to read Rigid Disk Block (RDB) from file or disk device.
#
# Examples:
# ---------
# Read RDB from hdf file on Windows platform
# python rdbinfo.py "c:\temp\4gb.hdf"
#
# Read RDB from drive letter F: on Windows platform
# python rdbinfo.py "\\.\F:"
#
# Read RDB from hdf file on macOS or Linux platform
# python rdbinfo.py "/tmp/4gb.hdf"
#
# Read RDB form disk device on macOS or Linux platform
# python rdbinfo.py "/dev/sdb"


"""
Script: RDB Info v1.0
"""

from __future__ import print_function
from subprocess import Popen, PIPE
from sys import platform,argv
import os
import stat as stdstat
import struct
import re
import math

class RigidDiskBlock:
    size = 0 # Size of the structure for checksums
    checksum = 0 # Checksum of the structure
    host_id = 0 # SCSI Target ID of host, not really used
    block_size = 0 # Size of disk blocks
    flags = 0 # RDB Flags
    bad_block_list = 0 # Bad block list
    partition_list = 0 # Partition list
    file_sys_hdr_List = 0 # File system header list
    drive_init_code = 0 # Drive specific init code
    boot_block_list = 0 # Amiga OS 4 Boot Blocks

    # physical drive caracteristics
    cylinders = 0 # Number of the cylinders of the drive
    sectors = 0 # Number of sectors of the drive
    heads = 0 # Number of heads of the drive
    interleave = 0 # Interleave 
    parking_zone = 0 # Head parking cylinder

    write_pre_comp = 0 # Starting cylinder of write precompensation 
    reduced_write = 0 # Starting cylinder of reduced write current
    step_rate = 0 # Step rate of the drive

    # logical drive caracteristics
    rdb_block_lo = 0 # low block of range reserved for hardblocks
    rdb_block_hi = 0 # high block of range for these hardblocks
    lo_cylinder = 0 # low cylinder of partitionable disk area
    hi_cylinder = 0 # high cylinder of partitionable data area
    cyl_blocks = 0 # number of blocks available per cylinder
    auto_park_seconds = 0 # zero for no auto park
    high_rsdk_block = 0 # highest block used by RDSK (not including replacement bad blocks)

    # drive identification
    disk_vendor = ""
    disk_product = ""
    disk_revision = ""
    controller_vendor = ""
    controller_product = ""
    controller_revision = ""

class PartitionBlock:
    size = 0 # Size of the structure for checksums
    checksum = 0 # Checksum of the structure
    host_id = 0 # SCSI Target ID of host, not really used 
    next_partition_block = 0 # Block number of the next PartitionBlock
    flags = 0 # Part Flags (NOMOUNT and BOOTABLE)

    dev_flags = 0 # Preferred flags for OpenDevice
    drive_name = "" # Preferred DOS device name: BSTR form

    size_of_vector = 0 # Size of Environment vector
    size_block = 0 # Size of the blocks in 32 bit words, usually 128
    sec_org = 0 # Not used; must be 0
    surfaces = 0 # Number of heads (surfaces)
    sectors_per_block = 0 # Disk sectors per block, used with SizeBlock, usually 1
    blocks_per_track = 0 # Blocks per track. drive specific
    reserved = 0 # DOS reserved blocks at start of partition.
    pre_alloc = 0 # DOS reserved blocks at end of partition
    interleave = 0 # Not used, usually 0
    low_cyl	= 0 # First cylinder of the partition
    high_cyl = 0 # Last cylinder of the partition
    num_buffer = 0 # Initial # DOS of buffers.
    buf_mem_type = 0 # Type of mem to allocate for buffers
    max_transfer = 0 # Max number of bytes to transfer at a time
    mask = 0 # Address Mask to block out certain memory
    boot_priority = 0 # Boot priority for autoboot
    dos_type = 0 # Dostype of the file system
    baud = 0 # Baud rate for serial handler
    control = 0 # Control word for handler/filesystem 
    boot_blocks = 0 # Number of blocks containing boot code 

class RigidDiskReader(object):
    def __init__(self, disk):
        self.disk = disk

        # constants
        self.BLOCK_SIZE = 512
        self.RDB_LOCATION_LIMIT = 16

    def read_char(self, block_data, offset, length):
        return struct.unpack_from('%ds' % length, block_data, offset)[0]

    def read_string(self, block_data, offset):
        length = struct.unpack_from('B', block_data, offset)[0]
        return self.read_char(block_data, offset + 1, length)      
    
    def read_long(self, block_data, offset):
        return struct.unpack_from('>l', block_data, offset)[0]

    def read_unsigned_long(self, block_data, offset):
        return struct.unpack_from('>L', block_data, offset)[0]

    def read_identifier(self, block_data, offset):
        return struct.unpack_from('4s', block_data, offset)[0]

    def find_rigid_disk_block(self):
        for block_index in range(0, self.RDB_LOCATION_LIMIT):
            block_offset = self.BLOCK_SIZE * block_index
            self.disk.seek(block_offset)
            block_data = self.disk.read(self.BLOCK_SIZE)
            identifier = self.read_identifier(block_data, 0)
            if identifier == "RDSK":
                return block_data
        return None 

    def read_rigid_disk_block(self):
        block_data = self.find_rigid_disk_block()
        if block_data == None:
            raise "Invalid rigid disk block"

        rigid_disk_block = RigidDiskBlock()
        rigid_disk_block.size = self.read_unsigned_long(block_data, 4)
        rigid_disk_block.checksum = self.read_long(block_data, 8)
        rigid_disk_block.host_id = self.read_unsigned_long(block_data, 12)
        rigid_disk_block.block_size = self.read_unsigned_long(block_data, 16)
        rigid_disk_block.flags = self.read_unsigned_long(block_data, 20)
        rigid_disk_block.bad_block_list = self.read_unsigned_long(block_data, 24)
        rigid_disk_block.partition_list = self.read_unsigned_long(block_data, 28)
        rigid_disk_block.file_sys_hdr_List = self.read_unsigned_long(block_data, 32)
        rigid_disk_block.drive_init_code = self.read_unsigned_long(block_data, 36)
        rigid_disk_block.boot_block_list = self.read_unsigned_long(block_data, 40)

        rigid_disk_block.cylinders = self.read_unsigned_long(block_data, 64)
        rigid_disk_block.sectors = self.read_unsigned_long(block_data, 68)
        rigid_disk_block.heads = self.read_unsigned_long(block_data, 72)
        rigid_disk_block.interleave = self.read_unsigned_long(block_data, 76)
        rigid_disk_block.parking_zone = self.read_unsigned_long(block_data, 80)

        rigid_disk_block.write_pre_comp = self.read_unsigned_long(block_data, 96)
        rigid_disk_block.reduced_write = self.read_unsigned_long(block_data, 100)
        rigid_disk_block.step_rate = self.read_unsigned_long(block_data, 104)

        rigid_disk_block.rdb_block_lo = self.read_unsigned_long(block_data, 128)
        rigid_disk_block.rdb_block_hi = self.read_unsigned_long(block_data, 132)
        rigid_disk_block.lo_cylinder = self.read_unsigned_long(block_data, 136)
        rigid_disk_block.hi_cylinder = self.read_unsigned_long(block_data, 140)
        rigid_disk_block.cyl_blocks = self.read_unsigned_long(block_data, 144)
        rigid_disk_block.auto_park_seconds = self.read_unsigned_long(block_data, 148)
        rigid_disk_block.high_rsdk_block = self.read_unsigned_long(block_data, 152)

        rigid_disk_block.disk_vendor = self.read_char(block_data, 160, 8)
        rigid_disk_block.disk_product = self.read_char(block_data, 168, 16)
        rigid_disk_block.disk_revision = self.read_char(block_data, 184, 4)
        rigid_disk_block.controller_vendor = self.read_char(block_data, 188, 8)
        rigid_disk_block.controller_product = self.read_char(block_data, 196, 16)
        rigid_disk_block.controller_revision = self.read_char(block_data, 212, 4)

        return rigid_disk_block

    def read_partition_block(self, block_data):
        identifier = self.read_identifier(block_data, 0)
        if identifier != "PART":
            raise "Invalid partition block"

        partition_block = PartitionBlock()
        partition_block.size = self.read_unsigned_long(block_data, 4)
        partition_block.checksum = self.read_long(block_data, 8)
        partition_block.host_id = self.read_unsigned_long(block_data, 12)
        partition_block.next_partition_block = self.read_unsigned_long(block_data, 16)
        partition_block.flags = self.read_unsigned_long(block_data, 20)

        partition_block.dev_flags = self.read_unsigned_long(block_data, 32)
        partition_block.drive_name = self.read_string(block_data, 36)

        partition_block.size_of_vector = self.read_unsigned_long(block_data, 128)
        partition_block.size_block = self.read_unsigned_long(block_data, 132)
        partition_block.sec_org = self.read_unsigned_long(block_data, 136)
        partition_block.surfaces = self.read_unsigned_long(block_data, 140)
        partition_block.sectors_per_block = self.read_unsigned_long(block_data, 144)
        partition_block.blocks_per_track = self.read_unsigned_long(block_data, 148)
        partition_block.reserved = self.read_unsigned_long(block_data, 152)
        partition_block.pre_alloc = self.read_unsigned_long(block_data, 156)
        partition_block.interleave = self.read_unsigned_long(block_data, 160)
        partition_block.low_cyl = self.read_unsigned_long(block_data, 164)
        partition_block.high_cyl = self.read_unsigned_long(block_data, 168)
        partition_block.num_buffer = self.read_unsigned_long(block_data, 172)
        partition_block.buf_mem_type = self.read_unsigned_long(block_data, 176)
        partition_block.max_transfer = self.read_unsigned_long(block_data, 180)
        partition_block.mask = self.read_unsigned_long(block_data, 184)
        partition_block.boot_priority = self.read_unsigned_long(block_data, 188)
        partition_block.dos_type = self.read_char(block_data, 192, 4)
        partition_block.baud = self.read_unsigned_long(block_data, 196)
        partition_block.control = self.read_unsigned_long(block_data, 200)
        partition_block.boot_blocks = self.read_unsigned_long(block_data, 204)

        return partition_block

    def read_partition_list(self, rigid_disk_block):
        partition_blocks = []
        partition_list = rigid_disk_block.partition_list
        partition_index = 1
        while True:
            partition_block_offset = rigid_disk_block.block_size * partition_list
            self.disk.seek(partition_block_offset)
            block_data = self.disk.read(self.BLOCK_SIZE)
            partition_block = self.read_partition_block(block_data)
            partition_blocks.append(partition_block)
            partition_list = partition_block.next_partition_block
            if partition_list <= 0 or partition_list == 0xFFFFFFFF or partition_index > 128:
                break
            partition_index += 1
        return partition_blocks

def format_bytes(size, precision = 0):
    base = math.log(size, 1024)
    units = ["", "K", "M", "G", "T"]
    return "%s %sB" % (round(math.pow(1024, base - math.floor(base)), precision), units[int(math.floor(base))])


# print usage and exit, if arguments are not defined
if len(argv) <= 1:
    print ("Usage: %s \"[PATH]\"" % argv[0])
    exit()

# get path
path = argv[1].strip()

# set disk path and change disk path to logical disk, if it matches drive letter
disk_path = path
if platform == "win32" and re.match(r'^[a-z]:$', disk_path, re.M|re.I):
    disk_path = "\\\\.\\%s" % disk_path 

# default disk size
disk_size = -1

# open disk path and read rigid disk blocks
with open(disk_path, 'rb') as disk:
    # get disk size
    # use powershell to get partition size, if platform is win32 and path is not a file
    if platform == "win32" and not os.path.isfile(path):
        drive_letter = None
        drive_letter_match = re.match(r'^([a-z]):$', path, re.M|re.I)
        logical_disk_match = re.match(r'\\\\\.\\([a-z]):$', path, re.M|re.I)
        if drive_letter_match:
            drive_letter = drive_letter_match.group(1)
        elif logical_disk_match:
            drive_letter = logical_disk_match.group(1)

        if drive_letter:
            cmd = "powershell -ExecutionPolicy Bypass -Command \"(Get-Partition -DriveLetter '%s').Size\"" % drive_letter
            proc = Popen(cmd, stdout=PIPE)
            proc.wait()
            disk_size = int(proc.stdout.read().strip())
    else:
        disk.seek(0, 2)
        disk_size = disk.tell()

    # read rigid disk blocks
    rigid_disk_reader = RigidDiskReader(disk)
    rigid_disk_block = rigid_disk_reader.read_rigid_disk_block()
    partition_blocks = rigid_disk_reader.read_partition_list(rigid_disk_block)

    # calculate drive size
    drive_size = rigid_disk_block.cylinders * rigid_disk_block.heads * rigid_disk_block.sectors * rigid_disk_reader.BLOCK_SIZE


print ("Disk:")
print ("-----")
print ("Path:                     %s" % path)

if disk_size > 0:
    print ("Size:                     %s (%d bytes)" % (format_bytes(disk_size, 1), disk_size))

# show physical drive
print ("")
print ("Physical drive:")
print ("---------------")
print ("Manufacturers Name:       %s" % rigid_disk_block.disk_vendor)
print ("Drive Name:               %s" % rigid_disk_block.disk_product)
print ("Drive Revision:           %s" % rigid_disk_block.disk_revision)
print ("")
print ("Cylinders:                %s" % rigid_disk_block.cylinders)
print ("Heads:                    %s" % rigid_disk_block.sectors)
print ("Blocks per Track:         %s" % rigid_disk_block.heads)
print ("Size:                     %s (%d bytes)" % (format_bytes(drive_size, 1), drive_size))

# show partitions
partition_index = 0
for partition_block in partition_blocks:
    partition_index += 1

    # calculate partition size
    partition_cylinders = partition_block.high_cyl - partition_block.low_cyl + 1
    partition_size = partition_cylinders * partition_block.surfaces * partition_block.blocks_per_track * rigid_disk_block.block_size
    
    dos_type_formatted = "%s\\%02d" % (struct.unpack_from('3s', partition_block.dos_type, 0)[0], struct.unpack_from('B', partition_block.dos_type, 3)[0])
    dos_type = hex(struct.unpack_from('>L', partition_block.dos_type, 0)[0])

    print ("")
    print ("Partition %d:" % partition_index)
    print ("------------")
    print ("Device Name:              %s" % partition_block.drive_name)
    print ("Start Cylinder:           %d" % partition_block.low_cyl)
    print ("End Cylylinder:           %d" % partition_block.high_cyl)
    print ("Total Cylinder:           %d" % partition_cylinders)
    print ("Size:                     %s (%d bytes)" % (format_bytes(partition_size, 1), partition_size))
    print ("Buffers:                  %d" % partition_block.num_buffer)
    print ("File System Block Size:   %d" % (partition_block.size_block * 4 * partition_block.sectors_per_block))

    # bootable partition flag
    if partition_block.flags & 0x1:
        print ("Bootable")
        print ("Boot Priority:            %d" % partition_block.boot_priority)

    # no mount partition flag
    if partition_block.flags & 0x2:
        print ("No Automount")

    print ("Mask:                     %s" % hex(partition_block.mask))
    print ("Max Transfer:             %s, (%d)" % (hex(partition_block.max_transfer), partition_block.max_transfer))
    print ("Dos Type:                 %s (%s)" % (dos_type, dos_type_formatted))
