namespace HstWbInstaller.Imager.ConsoleApp.Apis
{
    using System;
    using System.Collections.Generic;
    using System.Runtime.InteropServices;
    using System.Text;
    using Microsoft.Win32.SafeHandles;

    // https://github.com/t00/TestCrypt/blob/master/TestCrypt/PhysicalDrive.cs
    public class PhysicalDrive
    {
        #region Constants
        private const uint MAX_NUMBER_OF_DRIVES = 64;

        /// <summary>
        /// Retrieves extended information about the physical disk's geometry: type, number of cylinders, tracks per
        /// cylinder, sectors per track, and bytes per sector.
        /// </summary>
        private const uint IOCTL_DISK_GET_DRIVE_GEOMETRY_EX = 0x000700A0U;

        /// <summary>
        /// Retrieves information for each entry in the partition tables for a disk.
        /// </summary>
        private const uint IOCTL_DISK_GET_DRIVE_LAYOUT_EX = 0x00070050U;

        /// <summary>
        /// Retrieves the device type, device number, and, for a partitionable device, the partition number of a device.
        /// </summary>
        private const uint IOCTL_STORAGE_GET_DEVICE_NUMBER = 0x002D1080;

        /// <summary>
        /// The data area passed to a system call is too small.
        /// </summary>
        private const int ERROR_INSUFFICIENT_BUFFER = 0x7A;

        /// <summary>
        /// The data area passed to a system call is too small.
        /// </summary>
        private const int ERROR_MORE_DATA = 0xEA;
        #endregion

        #region Properties
        /// <summary>
        /// Gets information about all physical drives detected on this machine.
        /// </summary>
        public static List<DriveInfo> Drives 
        {
            get 
            {
                List<DriveInfo> driveInfoList = new List<DriveInfo>();
                // simply try to open all physical drives up to MAX_NUMBER_OF_DRIVES
                for (uint i = 0; i < MAX_NUMBER_OF_DRIVES; i++)
                {
                    // try to open the current physical drive
                    string volume = string.Format("\\\\.\\PhysicalDrive{0}", i);
                    SafeFileHandle hndl = DeviceApi.CreateFile(volume,
                                                               DeviceApi.GENERIC_READ,
                                                               DeviceApi.FILE_SHARE_READ | DeviceApi.FILE_SHARE_WRITE,
                                                               IntPtr.Zero,
                                                               DeviceApi.OPEN_EXISTING,
                                                               DeviceApi.FILE_ATTRIBUTE_READONLY,
                                                               IntPtr.Zero);
                    if (!hndl.IsInvalid)
                    {
                        IntPtr dgePtr = IntPtr.Zero;
                        IntPtr driveLayoutPtr = IntPtr.Zero;
                        try
                        {
                            // try to use the I/O-control IOCTL_DISK_GET_DRIVE_GEOMETRY_EX for the current physical drive
                            uint dummy = 0;
                            dgePtr = Marshal.AllocHGlobal(Marshal.SizeOf(typeof(DISK_GEOMETRY_EX)));
                            if (DeviceApi.DeviceIoControl(hndl, IOCTL_DISK_GET_DRIVE_GEOMETRY_EX, IntPtr.Zero, 0, dgePtr, (uint)Marshal.SizeOf(typeof(DISK_GEOMETRY_EX)), ref dummy, IntPtr.Zero))
                            {
                                // I/O-control has been invoked successfully, convert to DISK_GEOMETRY_EX structure 
                                DISK_GEOMETRY_EX dge = (DISK_GEOMETRY_EX)Marshal.PtrToStructure(dgePtr, typeof(DISK_GEOMETRY_EX));

                                // try to use the I/O-control IOCTL_DISK_GET_DRIVE_LAYOUT_EX to get information about the 
                                // partitions of the current physical drive: to determine the size of output buffer that is 
                                // required, caller should send this IOCTL request in a loop: every time the storage stack 
                                // rejects the IOCTL with an error message indicating that the buffer was too small, caller
                                // should double the buffer size                                    
                                int DRIVE_LAYOUT_BUFFER_SIZE = 1024;
                                int error;
                                do
                                {
                                    error = 0;
                                    driveLayoutPtr = Marshal.AllocHGlobal(DRIVE_LAYOUT_BUFFER_SIZE);
                                    if (DeviceApi.DeviceIoControl(hndl, IOCTL_DISK_GET_DRIVE_LAYOUT_EX, IntPtr.Zero, 0, driveLayoutPtr, (uint)DRIVE_LAYOUT_BUFFER_SIZE, ref dummy, IntPtr.Zero))
                                    {
                                        // I/O-control has been invoked successfully, convert to DRIVE_LAYOUT_INFORMATION_EX
                                        DRIVE_LAYOUT_INFORMATION_EX driveLayout = (DRIVE_LAYOUT_INFORMATION_EX)Marshal.PtrToStructure(driveLayoutPtr, typeof(DRIVE_LAYOUT_INFORMATION_EX));

                                        // add the physical drive information to the list
                                        DriveInfo driveInfo = new DriveInfo(i, dge.DiskSize, dge.Geometry, driveLayout.PartitionStyle);
                                        driveInfoList.Add(driveInfo);

                                        for (uint p = 0; p < driveLayout.PartitionCount; p++)
                                        {
                                            // now there comes some pointer arithmetic part because I have not found a better
                                            // way to handle variable sized structures in C#
                                            IntPtr ptr = new IntPtr(driveLayoutPtr.ToInt64() + Marshal.OffsetOf(typeof(DRIVE_LAYOUT_INFORMATION_EX), "PartitionEntry").ToInt64() + (p * Marshal.SizeOf(typeof(PARTITION_INFORMATION_EX))));
                                            PARTITION_INFORMATION_EX partInfo = (PARTITION_INFORMATION_EX)Marshal.PtrToStructure(ptr, typeof(PARTITION_INFORMATION_EX));
                                            if ((partInfo.PartitionStyle != PARTITION_STYLE.PARTITION_STYLE_MBR) || (partInfo.Mbr.RecognizedPartition))
                                            {
                                                driveInfo.Partitions.Add(partInfo);
                                            }
                                        }
                                    }
                                    else
                                    {
                                        error = Marshal.GetLastWin32Error();
                                        DRIVE_LAYOUT_BUFFER_SIZE *= 2;
                                    }
                                    Marshal.FreeHGlobal(driveLayoutPtr);
                                    driveLayoutPtr = IntPtr.Zero;
                                } while (error == ERROR_INSUFFICIENT_BUFFER);
                            }
                        }
                        finally
                        {
                            if (driveLayoutPtr != IntPtr.Zero)
                            {
                                Marshal.FreeHGlobal(driveLayoutPtr);
                            }
                            if (dgePtr != IntPtr.Zero)
                            {
                                Marshal.FreeHGlobal(dgePtr);
                            }
                            hndl.Close();
                        }
                    }
                }
                return driveInfoList;
            }
        }

        public static List<VolumeInfo> Volumes
        {
            get
            {
                // the task seems easy, but the WINAPI seems to miss the direct way: instead we have to probe all logical 
                // drives in order to find the one which matches the drive/partition number
                List<VolumeInfo> volumeInfoList = new List<VolumeInfo>();

                // start with finding the first logical drive
                StringBuilder sbVolumeName = new StringBuilder(64);
                IntPtr hFindVolume = DeviceApi.FindFirstVolume(sbVolumeName, (uint)sbVolumeName.Capacity);
                IntPtr sdnPtr = IntPtr.Zero;
                if (hFindVolume != DeviceApi.INVALID_HANDLE_VALUE)
                {
                    try
                    {
                        do
                        {
                            // open the current logical drive: the trailing backslash of the volume name has to be stripped
                            SafeFileHandle hndl = DeviceApi.CreateFile(sbVolumeName.ToString().TrimEnd('\\'),
                                                                       DeviceApi.GENERIC_READ,
                                                                       DeviceApi.FILE_SHARE_READ | DeviceApi.FILE_SHARE_WRITE,
                                                                       IntPtr.Zero,
                                                                       DeviceApi.OPEN_EXISTING,
                                                                       0,
                                                                       IntPtr.Zero);
                            if (!hndl.IsInvalid)
                            {
                                // try to use the I/O-control IOCTL_STORAGE_GET_DEVICE_NUMBER for the current logical drive
                                uint dummy = 0;
                                sdnPtr = Marshal.AllocHGlobal(Marshal.SizeOf(typeof(STORAGE_DEVICE_NUMBER)));
                                if (DeviceApi.DeviceIoControl(hndl, IOCTL_STORAGE_GET_DEVICE_NUMBER, IntPtr.Zero, 0, sdnPtr, (uint)Marshal.SizeOf(typeof(STORAGE_DEVICE_NUMBER)), ref dummy, IntPtr.Zero))
                                {
                                    // I/O-control has been invoked successfully, convert to STORAGE_DEVICE_NUMBER 
                                    // structure and request further information about the logical drive
                                    STORAGE_DEVICE_NUMBER sdn = (STORAGE_DEVICE_NUMBER)Marshal.PtrToStructure(sdnPtr, typeof(STORAGE_DEVICE_NUMBER));
                                    string label = string.Empty;
                                    string rootPath = string.Empty;
                                    StringBuilder sbLabel = new StringBuilder((int)(DeviceApi.MAX_PATH + 1));
                                    if (DeviceApi.GetVolumeInformation(sbVolumeName.ToString(), sbLabel, (uint)sbLabel.Capacity, ref dummy, ref dummy, ref dummy, null, 0))
                                    {
                                        label = sbLabel.ToString();
                                    }
                                    uint bufferLength;
                                    if (!DeviceApi.GetVolumePathNamesForVolumeName(sbVolumeName.ToString(), null, 0, out bufferLength))
                                    {
                                        if (Marshal.GetLastWin32Error() == ERROR_MORE_DATA)
                                        {
                                            StringBuilder sbRootPath = new StringBuilder((int)bufferLength);
                                            if (DeviceApi.GetVolumePathNamesForVolumeName(sbVolumeName.ToString(), sbRootPath, (uint)sbRootPath.Capacity, out bufferLength))
                                            {
                                                rootPath = sbRootPath.ToString().TrimEnd('\0').Split('\0')[0];
                                            }
                                        }
                                    }
                                    volumeInfoList.Add(new VolumeInfo(rootPath, label, sdn));
                                }
                                Marshal.FreeHGlobal(sdnPtr);
                                sdnPtr = IntPtr.Zero;
                                hndl.Close();
                            }
                        } while (DeviceApi.FindNextVolume(hFindVolume, sbVolumeName, (uint)sbVolumeName.Capacity));
                    }
                    finally
                    {
                        DeviceApi.FindVolumeClose(hFindVolume);
                        if (sdnPtr != IntPtr.Zero)
                        {
                            Marshal.FreeHGlobal(sdnPtr);
                        }
                    }
                }
                return volumeInfoList;
            }
        }
        #endregion

        #region Local Types
        public enum EMoveMethod : uint
        {
            Begin = 0,
            Current = 1,
            End = 2
        }

        /// <summary>
        /// Represents the various forms of device media.
        /// </summary>
        public enum MEDIA_TYPE
        {
            Unknown = 0x00,
            F5_1Pt2_512 = 0x01,
            F3_1Pt44_512 = 0x02,
            F3_2Pt88_512 = 0x03,
            F3_20Pt8_512 = 0x04,
            F3_720_512 = 0x05,
            F5_360_512 = 0x06,
            F5_320_512 = 0x07,
            F5_320_1024 = 0x08,
            F5_180_512 = 0x09,
            F5_160_512 = 0x0a,
            RemovableMedia = 0x0b,
            FixedMedia = 0x0c,
            F3_120M_512 = 0x0d,
            F3_640_512 = 0x0e,
            F5_640_512 = 0x0f,
            F5_720_512 = 0x10,
            F3_1Pt2_512 = 0x11,
            F3_1Pt23_1024 = 0x12,
            F5_1Pt23_1024 = 0x13,
            F3_128Mb_512 = 0x14,
            F3_230Mb_512 = 0x15,
            F8_256_128 = 0x16,
            F3_200Mb_512 = 0x17,
            F3_240M_512 = 0x18,
            F3_32M_512 = 0x19
        }

        /// <summary>
        /// Describes the geometry of disk devices and media.
        /// </summary>
        [StructLayout(LayoutKind.Explicit)]
        public struct DISK_GEOMETRY
        {
            /// <summary>
            /// The number of cylinders.
            /// </summary>
            [FieldOffset(0)]
            public Int64 Cylinders;

            /// <summary>
            /// The type of media. For a list of values, see MEDIA_TYPE.
            /// </summary>
            [FieldOffset(8)]
            public MEDIA_TYPE MediaType;

            /// <summary>
            /// The number of tracks per cylinder.
            /// </summary>
            [FieldOffset(12)]
            public uint TracksPerCylinder;

            /// <summary>
            /// The number of sectors per track.
            /// </summary>
            [FieldOffset(16)]
            public uint SectorsPerTrack;

            /// <summary>
            /// The number of bytes per sector.
            /// </summary>
            [FieldOffset(20)]
            public uint BytesPerSector;
        }

        /// <summary>
        /// Describes the extended geometry of disk devices and media.
        /// </summary>
        [StructLayout(LayoutKind.Explicit)]
        private struct DISK_GEOMETRY_EX
        {
            /// <summary>
            /// A DISK_GEOMETRY structure.
            /// </summary>
            [FieldOffset(0)]
            public DISK_GEOMETRY Geometry;

            /// <summary>
            /// The disk size, in bytes.
            /// </summary>
            [FieldOffset(24)]
            public Int64 DiskSize;

            /// <summary>
            /// Any additional data.
            /// </summary>
            [FieldOffset(32)]
            public Byte Data;
        }

        /// <summary>
        /// Represents the format of a partition.
        /// </summary>
        public enum PARTITION_STYLE : uint
        {
            /// <summary>
            /// Master boot record (MBR) format.
            /// </summary>
            PARTITION_STYLE_MBR = 0,
            
            /// <summary>
            /// GUID Partition Table (GPT) format.
            /// </summary>
            PARTITION_STYLE_GPT = 1,
            
            /// <summary>
            /// Partition not formatted in either of the recognized formats—MBR or GPT.
            /// </summary>
            PARTITION_STYLE_RAW = 2
        }

        /// <summary>
        /// Provides information about a drive's master boot record (MBR) partitions.
        /// </summary>
        [StructLayout(LayoutKind.Explicit)]
        private struct DRIVE_LAYOUT_INFORMATION_MBR
        {
            /// <summary>
            /// The signature of the drive.
            /// </summary>
            [FieldOffset(0)]
            public uint Signature;
        }

        /// <summary>
        /// Contains information about a drive's GUID partition table (GPT) partitions.
        /// </summary>
        [StructLayout(LayoutKind.Explicit)]
        private struct DRIVE_LAYOUT_INFORMATION_GPT
        {
            /// <summary>
            /// The GUID of the disk.
            /// </summary>
            [FieldOffset(0)]
            public Guid DiskId;

            /// <summary>
            /// The starting byte offset of the first usable block.
            /// </summary>
            [FieldOffset(16)]
            public Int64 StartingUsableOffset;

            /// <summary>
            /// The size of the usable blocks on the disk, in bytes.
            /// </summary>
            [FieldOffset(24)]
            public Int64 UsableLength;

            /// <summary>
            /// The maximum number of partitions that can be defined in the usable block.
            /// </summary>
            [FieldOffset(32)]
            public uint MaxPartitionCount;
        }

        /// <summary>
        /// Contains extended information about a drive's partitions.
        /// </summary>
        [StructLayout(LayoutKind.Explicit)]
        private struct DRIVE_LAYOUT_INFORMATION_EX
        {
            /// <summary>
            /// The style of the partitions on the drive enumerated by the PARTITION_STYLE enumeration.
            /// </summary>
            [FieldOffset(0)]
            public PARTITION_STYLE PartitionStyle;

            /// <summary>
            /// The number of partitions on a drive.
            /// 
            /// On disks with the MBR layout, this value is always a multiple of 4. Any partitions that are unused have
            /// a partition type of PARTITION_ENTRY_UNUSED.
            /// </summary>
            [FieldOffset(4)]
            public uint PartitionCount;

            /// <summary>
            /// A DRIVE_LAYOUT_INFORMATION_MBR structure containing information about the master boot record type 
            /// partitioning on the drive.
            /// </summary>
            [FieldOffset(8)]
            public DRIVE_LAYOUT_INFORMATION_MBR Mbr;

            /// <summary>
            /// A DRIVE_LAYOUT_INFORMATION_GPT structure containing information about the GUID disk partition type 
            /// partitioning on the drive.
            /// </summary>
            [FieldOffset(8)]
            public DRIVE_LAYOUT_INFORMATION_GPT Gpt;

            /// <summary>
            /// A variable-sized array of PARTITION_INFORMATION_EX structures, one structure for each partition on the 
            /// drive.
            /// </summary>
            [FieldOffset(48)]
            public PARTITION_INFORMATION_EX PartitionEntry;
        }

        /// <summary>
        /// Contains partition information specific to master boot record (MBR) disks.
        /// </summary>
        [StructLayout(LayoutKind.Explicit)]
        public struct PARTITION_INFORMATION_MBR
        {
            #region Constants
            /// <summary>
            /// An unused entry partition.
            /// </summary>
            public const byte PARTITION_ENTRY_UNUSED = 0x00;

            /// <summary>
            /// A FAT12 file system partition.
            /// </summary>
            public const byte PARTITION_FAT_12 = 0x01;

            /// <summary>
            /// A FAT16 file system partition.
            /// </summary>
            public const byte PARTITION_FAT_16 = 0x04;

            /// <summary>
            /// An extended partition.
            /// </summary>
            public const byte PARTITION_EXTENDED = 0x05;

            /// <summary>
            /// An IFS partition.
            /// </summary>
            public const byte PARTITION_IFS = 0x07;

            /// <summary>
            /// A FAT32 file system partition.
            /// </summary>
            public const byte PARTITION_FAT32 = 0x0B;

            /// <summary>
            /// A logical disk manager (LDM) partition.
            /// </summary>
            public const byte PARTITION_LDM = 0x42;

            /// <summary>
            /// An NTFT partition.
            /// </summary>
            public const byte PARTITION_NTFT = 0x80;

            /// <summary>
            /// A valid NTFT partition.
            /// 
            /// The high bit of a partition type code indicates that a partition is part of an NTFT mirror or striped array.
            /// </summary>
            public const byte PARTITION_VALID_NTFT = 0xC0;
            #endregion

            /// <summary>
            /// The type of partition. For a list of values, see Disk Partition Types.
            /// </summary>
            [FieldOffset(0)]
            [MarshalAs(UnmanagedType.U1)]
            public byte PartitionType;

            /// <summary>
            /// If this member is TRUE, the partition is bootable.
            /// </summary>
            [FieldOffset(1)]
            [MarshalAs(UnmanagedType.I1)]
            public bool BootIndicator;

            /// <summary>
            /// If this member is TRUE, the partition is of a recognized type.
            /// </summary>
            [FieldOffset(2)]
            [MarshalAs(UnmanagedType.I1)]
            public bool RecognizedPartition;

            /// <summary>
            /// The number of hidden sectors in the partition.
            /// </summary>
            [FieldOffset(4)]
            public uint HiddenSectors;
        }

        /// <summary>
        /// Contains GUID partition table (GPT) partition information.
        /// </summary>
        [StructLayout(LayoutKind.Explicit, CharSet = CharSet.Unicode)]
        public struct PARTITION_INFORMATION_GPT
        {
            /// <summary>
            /// A GUID that identifies the partition type.
            /// 
            /// Each partition type that the EFI specification supports is identified by its own GUID, which is 
            /// published by the developer of the partition.
            /// </summary>
            [FieldOffset(0)]
            public Guid PartitionType;

            /// <summary>
            /// The GUID of the partition.
            /// </summary>
            [FieldOffset(16)]
            public Guid PartitionId;

            /// <summary>
            /// The Extensible Firmware Interface (EFI) attributes of the partition.
            /// 
            /// </summary>
            [FieldOffset(32)]
            public UInt64 Attributes;

            /// <summary>
            /// A wide-character string that describes the partition.
            /// </summary>
            [FieldOffset(40)]
            [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 36)]
            public string Name;
        }
   
        /// <summary>
        /// Contains information about a disk partition.
        /// </summary>
        [StructLayout(LayoutKind.Explicit)]
        public struct PARTITION_INFORMATION_EX
        {
            /// <summary>
            /// The format of the partition. For a list of values, see PARTITION_STYLE.
            /// </summary>
            [FieldOffset(0)]
            public PARTITION_STYLE PartitionStyle;

            /// <summary>
            /// The starting offset of the partition.
            /// </summary>
            [FieldOffset(8)]
            public Int64 StartingOffset;

            /// <summary>
            /// The length of the partition, in bytes.
            /// </summary>
            [FieldOffset(16)]
            public Int64 PartitionLength;

            /// <summary>
            /// The number of the partition (1-based).
            /// </summary>
            [FieldOffset(24)]
            public uint PartitionNumber;

            /// <summary>
            /// If this member is TRUE, the partition information has changed. When you change a partition (with 
            /// IOCTL_DISK_SET_DRIVE_LAYOUT), the system uses this member to determine which partitions have changed
            /// and need their information rewritten.
            /// </summary>
            [FieldOffset(28)]
            [MarshalAs(UnmanagedType.I1)]
            public bool RewritePartition;

            /// <summary>
            /// A PARTITION_INFORMATION_MBR structure that specifies partition information specific to master boot 
            /// record (MBR) disks. The MBR partition format is the standard AT-style format.
            /// </summary>
            [FieldOffset(32)]
            public PARTITION_INFORMATION_MBR Mbr;

            /// <summary>
            /// A PARTITION_INFORMATION_GPT structure that specifies partition information specific to GUID partition 
            /// table (GPT) disks. The GPT format corresponds to the EFI partition format.
            /// </summary>
            [FieldOffset(32)]
            public PARTITION_INFORMATION_GPT Gpt;
        }

        /// <summary>
        /// Contains information about a device. This structure is used by the IOCTL_STORAGE_GET_DEVICE_NUMBER control 
        /// code.
        /// </summary>
        [StructLayout(LayoutKind.Explicit)]
        public struct STORAGE_DEVICE_NUMBER
        {
            /// <summary>
            /// The type of device. Values from 0 through 32,767 are reserved for use by Microsoft. Values from 32,768
            /// through 65,535 are reserved for use by other vendors.
            /// </summary>
            [FieldOffset(0)]
            public ushort DeviceType;

            /// <summary>
            /// The number of this device.
            /// </summary>
            [FieldOffset(4)]
            public uint DeviceNumber;

            /// <summary>
            /// The partition number of the device, if the device can be partitioned. Otherwise, this member is –1.
            /// </summary>
            [FieldOffset(8)]
            public uint PartitionNumber;
        };

        /// <summary>
        /// Describes a Cylinder, Head, Sector (C/H/S) address.
        /// </summary>
        public struct CylinderHeadSector
        {
            /// <summary>
            /// The number of cylinders.
            /// </summary>
            public Int64 Cylinders;

            /// <summary>
            /// The number of tracks per cylinder.
            /// </summary>
            public uint TracksPerCylinder;

            /// <summary>
            /// The number of sectors per track.
            /// </summary>
            public uint SectorsPerTrack;

            public override string ToString()
            {
                return string.Format("{0}/{1}/{2}", Cylinders, TracksPerCylinder, SectorsPerTrack);
            }
        }

        public class DriveInfo
        {
            #region Properties
            /// <summary>
            /// Gets or sets the volume identifier of the physical drive.
            /// </summary>
            public uint DriveNumber { get; set; }

            /// <summary>
            /// Gets or sets the disk size, in bytes.
            /// </summary>
            public Int64 Size { get; set; }
            
            /// <summary>
            /// Gets or sets the disk geometry of the physical drive.
            /// </summary>
            public DISK_GEOMETRY Geometry { get; set; }

            /// <summary>
            /// Gets or sets the style of the partitions on the drive.
            /// </summary>
            public PARTITION_STYLE PartitionStyle  { get; set; }
         
            /// <summary>
            /// The list of partitions of the physical drive.
            /// </summary>
            public List<PARTITION_INFORMATION_EX> Partitions  { get; set; }
            #endregion

            #region Constructors
            /// <summary>
            /// Constructor.
            /// </summary>
            /// <param name="volume">The volume identifier of the physical drive.</param>
            /// <param name="size">The disk size, in bytes.</param>
            /// <param name="geometry">The disk geometry of the physical drive.</param>
            /// <param name="partitionStyle">The style of the partitions on the drive.</param>
            public DriveInfo(uint driveNumber, Int64 size, DISK_GEOMETRY geometry, PARTITION_STYLE partitionStyle)
            {
                DriveNumber = driveNumber;
                Size = size;
                Geometry = geometry;
                PartitionStyle = partitionStyle;
                Partitions = new List<PARTITION_INFORMATION_EX>();
            }
            #endregion

            public override string ToString()
            {
                return string.Format("PhysicalDrive{0} ({1})", DriveNumber, PhysicalDrive.GetAsBestFitSizeUnit(Size));
            }
        }

        public class VolumeInfo
        {
            #region Properties
            /// <summary>
            /// Gets or sets the volume's drive letter (for example, X:\) or the path of a mounted folder that is 
            /// associated with the volume.
            /// </summary>
            public string RootPath { get; set; }

            /// <summary>
            /// Gets or sets the label of a file system volume.
            /// </summary>
            public string Label { get; set; }

            /// <summary>
            /// Gets or sets the information about the device.
            /// </summary>
            public STORAGE_DEVICE_NUMBER DeviceInfo { get; set; }
            #endregion

            #region Constructors
            /// <summary>
            /// Constructor.
            /// </summary>
            /// <param name="rootPath">The volume's drive letter (for example, X:\) or the path of a mounted folder
            /// that is associated with the volume.</param>
            /// <param name="label">The label of a file system volume.</param>
            /// <param name="deviceInfo">Information about the device.</param>
            public VolumeInfo(string rootPath, string label, STORAGE_DEVICE_NUMBER deviceInfo)
            {
                RootPath = rootPath;
                Label = label;
                DeviceInfo = deviceInfo;
            }
            #endregion
        }
        #endregion

        #region Methods
        public static void Read(uint volume, Int64 address, uint length, byte[] data)
        {
            // try to open the current physical drive
            SafeFileHandle hndl = DeviceApi.CreateFile(string.Format("\\\\.\\PhysicalDrive{0}", volume),
                                                       DeviceApi.GENERIC_READ,
                                                       DeviceApi.FILE_SHARE_READ | DeviceApi.FILE_SHARE_WRITE, 
                                                       IntPtr.Zero,
                                                       DeviceApi.OPEN_EXISTING,
                                                       DeviceApi.FILE_ATTRIBUTE_READONLY, 
                                                       IntPtr.Zero);
            if (!hndl.IsInvalid)
            {
                // set the file pointer to the requested address
                if (DeviceApi.SetFilePointerEx(hndl, address, out _, DeviceApi.EMoveMethod.Begin))
                {
                    // read the requested data from the physical drive
                    uint dummy;
                    if (!DeviceApi.ReadFile(hndl, data, length, out dummy, IntPtr.Zero))
                    {
                        throw new System.IO.IOException("\"ReadFile\" API call failed");
                    }
                }
                else
                {
                    throw new System.IO.IOException("\"SetFilePointerEx\" API call failed");
                }
                hndl.Close();
            }
        }

        /// <summary>
        /// Returns a string containing the best-fitting size and unit of the given size in bytes.
        /// </summary>
        /// <param name="size">Size in bytes that should be converted to the best-fitting unit.</param>
        /// <returns>The string containing the best-fitting size and unit of the given size in bytes.</returns>
        public static string GetAsBestFitSizeUnit(double size)
        {
            string[] units = { "Bytes", "KB", "MB", "GB", "TB", "PB", "EB" };

            double nextSize = size / 1000.0;
            int i = 0;
            while (nextSize >= 1.0)
            {
                i++;
                size = nextSize;
                nextSize = size / 1000.0;
            }

            return string.Format("{0:0.00} {1}", size, units[i]);
        }

        public static CylinderHeadSector LbaToChs(Int64 lba, DISK_GEOMETRY geometry)
        {
            CylinderHeadSector chs;
            chs.Cylinders = (lba / (geometry.TracksPerCylinder * geometry.SectorsPerTrack));
            Int64 tmp = lba % (geometry.TracksPerCylinder * geometry.SectorsPerTrack);
            chs.TracksPerCylinder = (uint)(tmp / geometry.SectorsPerTrack);
            chs.SectorsPerTrack = (uint)((tmp % geometry.SectorsPerTrack) + 1);
            return chs;
        }

        public static Int64 ChsToLba(CylinderHeadSector chs, DISK_GEOMETRY geometry)
        {
            return (chs.Cylinders * geometry.TracksPerCylinder * geometry.SectorsPerTrack) +
                   (chs.TracksPerCylinder * geometry.SectorsPerTrack) + 
                   (chs.SectorsPerTrack - 1);
        }
        #endregion
    }
}