#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
# Win32 Disk Reader
# Author: Henrik Noerfjand Stengaard
# Date: 2018-02-17
#
# A python script to read Windows disk device.
#
# References:
# http://pydoc.net/watchdog/0.8.2/watchdog.utils.win32stat/
# https://github.com/maxpat78/FATtools/blob/master/disk.py
# http://pydoc.net/RSFile/1.1/rsbackends.pywin32_ctypes/


import ctypes
import ctypes.wintypes
import stat as stdstat

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

# example reading drive letter D:
win32_disk_reader = Win32DiskReader()
win32_disk_reader.open("\\\\.\\D:")
data = win32_disk_reader.read(512)
win32_disk_reader.close()
