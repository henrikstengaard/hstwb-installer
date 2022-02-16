namespace HstWbInstaller.Imager.Core.Tests
{
    using System.IO;
    using System.Linq;
    using System.Threading.Tasks;
    using PhysicalDrives;
    using Xunit;

    public class GivenLsBlkReader
    {
        [Fact]
        public async Task WhenParseJsonOutputFromLsBlkThenLsBlkIsReturned()
        {
            var lsBlk = LsBlkReader.ParseLsBlk(await File.ReadAllTextAsync(@"TestData\lsblk.json"));

            Assert.NotNull(lsBlk);
            Assert.NotEmpty(lsBlk.BlockDevices);

            var blockDevices = lsBlk.BlockDevices.ToList();
            Assert.Equal(2, blockDevices.Count);

            var blockDevice1 = blockDevices[0];
            Assert.Equal("disk", blockDevice1.Type);
            Assert.Equal("WDC_WDS500G2B0B-00YS70", blockDevice1.Model);
            Assert.Equal("/dev/sda", blockDevice1.Path);
            Assert.Equal(500107862016, blockDevice1.Size);
            Assert.Equal("Argon   ", blockDevice1.Vendor);
            Assert.False(blockDevice1.Removable);

            var blockDevice2 = blockDevices[1];
            Assert.Equal("disk", blockDevice2.Type);
            Assert.Equal("Cruzer_Fit", blockDevice2.Model);
            Assert.Equal("/dev/sdb", blockDevice2.Path);
            Assert.Equal(15682240512, blockDevice2.Size);
            Assert.Equal("SanDisk'", blockDevice2.Vendor);
            Assert.True(blockDevice2.Removable);
        }
    }
}