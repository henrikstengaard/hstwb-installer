#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
# RDB Info
# Author: Henrik Noerfjand Stengaard
# Date: 2018-02-15
#
# http://pydoc.net/watchdog/0.8.2/watchdog.utils.win32stat/
# https://github.com/maxpat78/FATtools/blob/master/disk.py
# http://pydoc.net/RSFile/1.1/rsbackends.pywin32_ctypes/
# 

"""
Script: RDB Info v1.0
"""

from __future__ import print_function
import ctypes
import ctypes.wintypes
import stat as stdstat
import struct

class Win32DiskReader(object):
    """
    Constructor
    """
    def __init__(self):
        # constants
        self.INVALID_HANDLE_VALUE = ctypes.c_void_p(-1).value
        self.OPEN_EXISTING = 3
        self.GENERIC_READ = 0x80000000
        self.FILE_READ_ATTRIBUTES = 0x80
        self.FILE_ATTRIBUTE_NORMAL = 0x80
        self.FILE_ATTRIBUTE_READONLY = 0x1
        self.FILE_ATTRIBUTE_DIRECTORY = 0x10
        self.FILE_FLAG_BACKUP_SEMANTICS = 0x02000000
        self.FILE_FLAG_OPEN_REPARSE_POINT = 0x00200000
        self.FILE_FLAG_NO_BUFFERING = 0x20000000

        # kernel32 create file
        self.CreateFile = ctypes.windll.kernel32.CreateFileW
        self.CreateFile.restype = ctypes.wintypes.HANDLE
        self.CreateFile.argtypes = (
            ctypes.c_wchar_p,
            ctypes.wintypes.DWORD,
            ctypes.wintypes.DWORD,
            ctypes.c_void_p,
            ctypes.wintypes.DWORD,
            ctypes.wintypes.DWORD,
            ctypes.wintypes.HANDLE,
        )

        # kernel32 read file
        self.ReadFile = ctypes.windll.kernel32.ReadFile        
        self.ReadFile.restype = ctypes.wintypes.BOOL
        self.ReadFile.argtypes = (
            ctypes.wintypes.HANDLE,
            ctypes.wintypes.LPVOID,
            ctypes.wintypes.DWORD,
            ctypes.POINTER(ctypes.wintypes.DWORD),
            ctypes.wintypes.LPVOID)

        # kernel32 set file pointer ex
        self.SetFilePointerEx = ctypes.windll.kernel32.SetFilePointerEx
        self.SetFilePointerEx.restype = ctypes.wintypes.BOOL
        self.SetFilePointerEx.argtypes = (
            ctypes.wintypes.HANDLE,
            ctypes.c_longlong,
            ctypes.POINTER(ctypes.c_longlong),
            ctypes.wintypes.DWORD)

        # kernel32 close handle
        self.CloseHandle = ctypes.windll.kernel32.CloseHandle
        self.CloseHandle.restype = ctypes.wintypes.BOOL
        self.CloseHandle.argtypes = (ctypes.wintypes.HANDLE,)

        self.handle = None
        self._pos = 0
    """
    Open file
    """
    def open(self, path):
        self.handle = self.CreateFile(path,
            self.GENERIC_READ,
            0x1,
            None,
            self.OPEN_EXISTING,
            self.FILE_FLAG_NO_BUFFERING,
            None)
        if self.handle == self.INVALID_HANDLE_VALUE:
            raise ctypes.WinError()

    """
    Read
    """
    def read(self, length):
        data = ctypes.create_string_buffer(length)
        bytes_read = ctypes.wintypes.DWORD(0)            
        ret = self.ReadFile(
            self.handle,
            data,
            length,
            ctypes.byref(bytes_read),
            None)
        if ret == 0:
            raise ctypes.WinError()
        return data

    """
    Seek
    """
    def seek(self, offset, whence=0):
        if whence == 0:
            npos = offset
        elif whence == 1:
            npos = self._pos + offset
        else:
            npos = self._pos - offset
        if self._pos == npos:
            return
        n = ctypes.c_longlong(offset)
        if 0xFFFFFFFF == self.SetFilePointerEx(self.handle, offset&0xFFFFFFFF, ctypes.byref(n), whence):
            raise ctypes.WinError()
        self._pos = npos

    """
    Close
    """
    def close(self):
        self.CloseHandle(self.handle)

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

class HdfDiskReader(object):
    def __init__(self, reader):
        self.reader = reader

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
            self.reader.seek(block_offset)
            block_data = self.reader.read(self.BLOCK_SIZE)
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

        return partition_block

    def read_partition_list(self, rigid_disk_block):
        partition_blocks = []
        partition_list = rigid_disk_block.partition_list
        partition_index = 1
        while True:
            partition_block_offset = rigid_disk_block.block_size * partition_list
            self.reader.seek(partition_block_offset)
            block_data = self.reader.read(self.BLOCK_SIZE)
            partition_block = self.read_partition_block(block_data)
            partition_blocks.append(partition_block)
            partition_list = partition_block.next_partition_block
            if partition_list <= 0 or partition_list == 0xFFFFFFFF or partition_index > 128:
                break
            partition_index += 1
        return partition_blocks

DISK_READER = Win32DiskReader()
DISK_READER.open("c:\\temp\\hdf_repack\\4gb.hdf")
HDF_DISK_READER = HdfDiskReader(DISK_READER)

rigid_disk_block = HDF_DISK_READER.read_rigid_disk_block()
partition_blocks = HDF_DISK_READER.read_partition_list(rigid_disk_block)

# calculate drive size
DRIVE_SIZE = rigid_disk_block.cylinders * rigid_disk_block.heads * rigid_disk_block.sectors * HDF_DISK_READER.BLOCK_SIZE

print ("Physical drive:")
print ("---------------")
print ("Manufacturers Name = %s" % rigid_disk_block.disk_vendor)
print ("Drive Name = %s" % rigid_disk_block.disk_product)
print ("Drive Revision = %s" % rigid_disk_block.disk_revision)
print ("")
print ("Cylinders:          %s" % rigid_disk_block.cylinders)
print ("Heads:              %s" % rigid_disk_block.sectors)
print ("Blocks per Track:   %s" % rigid_disk_block.heads)
print ("Size:   %d" % DRIVE_SIZE)

for partition_block in partition_blocks:
    print ("host id:          %s" % partition_block.host_id)
    print ("next block:          %s" % partition_block.next_partition_block)
    print ("drive name:          %s" % partition_block.drive_name)

DISK_READER.close()
