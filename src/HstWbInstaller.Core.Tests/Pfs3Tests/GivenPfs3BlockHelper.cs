namespace HstWbInstaller.Core.Tests.Pfs3Tests
{
    using System.IO;
    using System.Threading.Tasks;
    using Extensions;
    using IO.Pfs3;
    using IO.RigidDiskBlocks;
    using Xunit;
    using BlockHelper = IO.Pfs3.BlockHelper;

    public class GivenPfs3BlockHelper
    {
        [Fact(Skip = "Manually used for testing")]
        public void WhenMakeRootBlockThen()
        {
            var diskName = "Workbench";

            var globalData = new globaldata(new MemoryStream())
            {
                NumBuffers = 80,
                blocksize = 512,
                TotalSectors = 1024 * 1024 * 100 / 512
            };
            
            var rootBlock = Format.MakeRootBlock(diskName, globalData);
        }

        [Fact]
        public async Task WhenFormatThen()
        {
            var diskName = "Workbench";
            var partitionBlock = new PartitionBlock
            {
                BlocksPerTrack = 63,
                BootPriority = 0,
                DosType = FormatHelper.FormatDosType("PFS3"),
                DriveName = "DH0",
                FileSystemBlockSize = 512,
                HighCyl = 610,
                LowCyl = 2,
                Mask = 2147483646U,
                MaxTransfer = 130560,
                NumBuffer = 80,
                PartitionSize = 314302464L,
                PreAlloc = 0,
                Reserved = 2,
                Sectors = 1,
                Surfaces = 16
            };

            await using var stream = File.Open(@"pfs3_format_partition.bin", FileMode.Create, FileAccess.ReadWrite);
            stream.SetLength(partitionBlock.PartitionSize);
            
            await Format.Pfs3Format(stream, partitionBlock, diskName);
        }
        
        [Fact(Skip = "Manually used for testing")]
        public async Task Dump()
        {
            var stream = File.OpenRead(@"d:\Temp\4gb_amigaos_39_install\4gb.hdf");
            stream.Seek(63 * 2 * 16 * 512, SeekOrigin.Begin);

            var bytes = await stream.ReadBytes(1024 * 1024);
            await File.WriteAllBytesAsync(@"d:\Temp\4gb_amigaos_39_install\part1.bin", bytes);
        }
    }
}