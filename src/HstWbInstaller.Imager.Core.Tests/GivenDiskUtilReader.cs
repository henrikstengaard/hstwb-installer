namespace HstWbInstaller.Imager.Core.Tests
{
    using System.IO;
    using System.Linq;
    using PhysicalDrives;
    using Xunit;

    public class GivenDiskUtilReader
    {
        [Fact]
        public void WhenParseListOutputFromDiskUtilThenDisksAreReturned()
        {
            var disks = DiskUtilReader.ParseList(File.OpenRead(@"TestData\diskutil-list.plist")).ToList();
            
            Assert.Single(disks);
            var disk = disks.First();
            Assert.Equal("disk2", disk.DeviceIdentifier);
            Assert.Single(disk.Partitions);
            var partition = disk.Partitions.First();
            Assert.Equal("disk2s1", partition.DeviceIdentifier);
        }
        
        [Fact]
        public void WhenParseInfoOutputFromDiskUtilThenInfoIsReturned()
        {
            var info = DiskUtilReader.ParseInfo(File.OpenRead(@"TestData\diskutil-info-disk.plist"));
            
            Assert.NotNull(info);
            Assert.Equal("USB", info.BusProtocol);
            Assert.Equal("SanDisk' Cruzer Fit Media", info.IoRegistryEntryName);
            Assert.Equal(15682240512, info.Size);
            Assert.Equal("/dev/disk2", info.DeviceNode);
            Assert.Equal("Generic", info.MediaType);
        }
    }
}