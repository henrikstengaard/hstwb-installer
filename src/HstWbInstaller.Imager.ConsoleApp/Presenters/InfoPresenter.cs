namespace HstWbInstaller.Imager.ConsoleApp.Presenters
{
    using System;
    using System.Collections.Generic;
    using Core.Commands;
    using Core.Extensions;
    using HstWbInstaller.Core.IO.RigidDiskBlocks;

    public static class InfoPresenter
    {
        public static void PresentInfo(IEnumerable<MediaInfo> mediaInfos)
        {
            var diskNumber = 0;
            foreach (var mediaInfo in mediaInfos)
            {
                Console.WriteLine($"Disk {++diskNumber}:");
                PresentInfo(mediaInfo);
                Console.WriteLine();
            }
        }
        
        public static void PresentInfo(MediaInfo mediaInfo)
        {
            Console.WriteLine(
                $"Path: {mediaInfo.Path}");
            Console.WriteLine(
                $"Path: {mediaInfo.Model}");
            Console.WriteLine(
                $"Physical drive: {(mediaInfo.IsPhysicalDrive ? "Yes": "No")}");
            Console.WriteLine(
                $"Type: {mediaInfo.Type}");
            Console.WriteLine(
                $"Disk size: {mediaInfo.DiskSize.FormatBytes()} ({mediaInfo.DiskSize} bytes)");
            var rigidDiskBlock = mediaInfo.RigidDiskBlock;
            if (rigidDiskBlock != null)
            {
                Console.WriteLine("");
                Console.WriteLine("Rigid disk block:");
                Console.WriteLine($"Manufacturers name = {rigidDiskBlock.DiskVendor}");
                Console.WriteLine($"Drive name = {rigidDiskBlock.DiskProduct}");
                Console.WriteLine($"Drive revision = {rigidDiskBlock.DiskRevision}");
                Console.WriteLine("");
                Console.WriteLine($"Cylinders = {rigidDiskBlock.Cylinders}");
                Console.WriteLine($"Heads = {rigidDiskBlock.Heads}");
                Console.WriteLine(
                    $"Disk Size = {rigidDiskBlock.DiskSize.FormatBytes()} ({rigidDiskBlock.DiskSize} bytes)");
                Console.WriteLine($"Blocks per track = {rigidDiskBlock.Sectors}");
                Console.WriteLine($"Blocks per cylinder = {rigidDiskBlock.CylBlocks}");
                Console.WriteLine($"Park head where cylinder = {rigidDiskBlock.ParkingZone}");

                var partitionNumber = 0;
                foreach (var partitionBlock in rigidDiskBlock.PartitionBlocks)
                {
                    Console.WriteLine("");
                    Console.WriteLine($"Partition {++partitionNumber}:");
                    Console.WriteLine($"Device name = {partitionBlock.DriveName}");
                    Console.WriteLine($"Start cylinders = {partitionBlock.LowCyl}");
                    Console.WriteLine($"End cylinders = {partitionBlock.HighCyl}");
                    Console.WriteLine($"Total cylinders = {partitionBlock.HighCyl - partitionBlock.LowCyl + 1}");
                    Console.WriteLine($"Buffers = {partitionBlock.NumBuffer}");
                    Console.WriteLine(
                        $"File system block size = {partitionBlock.SizeBlock * 4 * partitionBlock.Sectors}");
                    Console.WriteLine(
                        $"Reserved = {partitionBlock.Reserved} (DOS Blocks reserved at the beginning of partition)");
                    Console.WriteLine(
                        $"PreAlloc = {partitionBlock.PreAlloc} (DOS Blocks reserved at the end of partition)");

                    var partitionFlags = (PartitionBlock.PartitionFlagsEnum)partitionBlock.Flags;

                    if (partitionFlags.HasFlag(PartitionBlock.PartitionFlagsEnum.Bootable))
                    {
                        Console.WriteLine($"Bootable, Boot Priority = {partitionBlock.BootPriority}");
                    }

                    if (partitionFlags.HasFlag(PartitionBlock.PartitionFlagsEnum.NoMount))
                    {
                        Console.WriteLine("No Automount");
                    }

                    var dosTypeIdentifier = new byte[3];
                    Array.Copy(partitionBlock.DosType, 0, dosTypeIdentifier, 0, 3);
                    var dosTypeFormatted = string.Concat(
                        System.Text.Encoding.GetEncoding("ISO-8859-1").GetString(dosTypeIdentifier),
                        "\\", $"{partitionBlock.DosType[3]:d}");

                    Console.WriteLine($"Mask = 0x{partitionBlock.Mask.FormatHex()}");
                    Console.WriteLine(
                        $"Max Transfer = 0x{partitionBlock.MaxTransfer.FormatHex()}, ({partitionBlock.MaxTransfer})");
                    Console.WriteLine(
                        $"Dos Type = 0x{partitionBlock.DosType.FormatHex()}, ({dosTypeFormatted})");
                    Console.WriteLine(
                        $"Partition Size = {partitionBlock.PartitionSize.FormatBytes()} ({partitionBlock.PartitionSize} bytes)");
                }
            }
            else
            {
                Console.WriteLine("No rigid disk block present");
            }
        }
    }
}