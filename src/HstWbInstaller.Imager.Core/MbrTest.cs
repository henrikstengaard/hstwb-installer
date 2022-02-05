namespace HstWbInstaller.Imager.Core
{
    using System;
    using System.IO;
    using System.Text;
    using DiscUtils;
    using DiscUtils.Fat;
    using DiscUtils.Partitions;
    //using DiscUtils.Vhd;
    using DiscUtils.Streams;
    using DiscUtils.Raw;

    public class MbrTest
    {
        public void Create()
        {
            var size = 1024 * 1024 * 1024; // 1gb


            var sectorSize = 512;
            var headsPerCylinder = 16;
            var sectorsPerTrack = 63;
            var cylinders = size / (headsPerCylinder * sectorsPerTrack * sectorSize);

            var path = @"d:\temp\mbr.img";
            
            using var imgStream = File.Create(path);
            //var disk = Disk.Initialize(imgStream, Ownership.None, size, new Geometry(cylinders, headsPerCylinder, sectorsPerTrack, sectorSize));
            var disk = Disk.Initialize(imgStream, Ownership.None, size);
            BiosPartitionTable.Initialize(disk, WellKnownPartitionType.WindowsFat);

            // var bootSector = new byte[512];
            // imgStream.Position = 0;
            // imgStream.Read(bootSector, 0, bootSector.Length);
            // EndianUtilities.WriteBytesLittleEndian((ushort)sectorSize, bootSector, 11);
            // //EndianUtilities.ToUInt16LittleEndian(bpb, 11);
            // imgStream.Position = 0;
            // imgStream.Write(bootSector, 0, bootSector.Length);
            
            var partitionSize = 1024 * 1024 * 512;
            var partitionCylinders = partitionSize / (headsPerCylinder * sectorsPerTrack * sectorSize);
            var partitionSectors = partitionSize / sectorSize;
            
            // using FatFileSystem fs = FatFileSystem.FormatPartition(imgStream, "AmigaTest",
            //     new Geometry(partitionCylinders, headsPerCylinder, sectorsPerTrack, sectorSize), 1024 * 512,
            //     partitionSectors, 0);
            // fs.CreateDirectory(@"TestDir\CHILD");
            using FatFileSystem fs = FatFileSystem.FormatPartition(disk, 0, "AmigaMBRTest");

            var bootSector = new byte[512];
            imgStream.Position = 0;
            imgStream.Read(bootSector, 0, bootSector.Length);
            
            fs.CreateDirectory(@"TestDir\CHILD");

            using var s = fs.OpenFile("foo.txt", FileMode.Create);
            using var writer = new StreamWriter(s, Encoding.UTF8);
            writer.WriteLine("hello");
            
            fs.Dispose();
            disk.Dispose();
        }

        public void Read()
        {
            var path = @"d:\temp\mbr.img";
            
            DiscUtils.Containers.SetupHelper.SetupContainers();
            DiscUtils.FileSystems.SetupHelper.SetupFileSystems();
            var disk = VirtualDisk.OpenDisk(path, FileAccess.ReadWrite);
            var fs = new FatFileSystem(disk.Partitions[0].Open());
            var directories = fs.GetDirectories("");
            var files = fs.GetFiles("");
        }

        private int ConvertToSector(long offset)
        {
            return Convert.ToInt32(offset / 512);
        }
    }
}