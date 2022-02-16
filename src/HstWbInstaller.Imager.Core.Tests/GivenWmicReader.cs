namespace HstWbInstaller.Imager.Core.Tests
{
    using System.IO;
    using System.Linq;
    using System.Threading.Tasks;
    using PhysicalDrives;
    using Xunit;

    public class GivenWmicReader
    {
        [Fact]
        public async Task WhenParseCsvOutputFromWmicThenWmicDiskDrivesAreReturned()
        {
            var wmicDiskDrives = WmicReader.ParseWmicCsv(await File.ReadAllTextAsync(@"TestData\wmic.csv")).ToList();

            Assert.NotNull(wmicDiskDrives);
            Assert.NotEmpty(wmicDiskDrives);
            Assert.Equal(2, wmicDiskDrives.Count);

            var wmicDiskDrive1 = wmicDiskDrives[0];
            Assert.Equal("External hard disk media", wmicDiskDrive1.MediaType);
            Assert.Equal("  SCSI Disk Device", wmicDiskDrive1.Model);
            Assert.Equal("\\\\.\\PHYSICALDRIVE3", wmicDiskDrive1.Name);
            Assert.Equal(120031511040, wmicDiskDrive1.Size);
            Assert.Equal("SCSI", wmicDiskDrive1.InterfaceType);
            
            var wmicDiskDrive2 = wmicDiskDrives[1];
            Assert.Equal("Removable Media", wmicDiskDrive2.MediaType);
            Assert.Equal("SanDisk' Cruzer Fit USB Device", wmicDiskDrive2.Model);
            Assert.Equal("\\\\.\\PHYSICALDRIVE2", wmicDiskDrive2.Name);
            Assert.Equal(15677383680, wmicDiskDrive2.Size);
            Assert.Equal("USB", wmicDiskDrive2.InterfaceType);
        }
    }
}