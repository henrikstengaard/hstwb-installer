namespace HstWbInstaller.Core.Tests.Pfs3Tests
{
    using System.IO;
    using System.Linq;
    using System.Threading.Tasks;
    using Extensions;
    using IO.Pfs3;
    using IO.Pfs3.Blocks;
    using IO.RigidDiskBlocks;
    using IO.Vhds;
    using Xunit;
    using BlockHelper = IO.Pfs3.BlockHelper;

    public class GivenPfs3BlockHelper
    {
        [Fact]
        public async Task WhenCreateHdfWithPfs3FormattedUsingHstWb()
        {
            var path = @"d:\Temp\pfs3_format_hstwb\pfs3_format_hstwb.hdf";

            var rigidDiskBlock = await RigidDiskBlock
                .Create(300.MB().ToUniversalSize())
                .AddFileSystem("PFS3", await File.ReadAllBytesAsync(@"TestData\pfs3aio"))
                .AddPartition("DH0", bootable: true)
                .WriteToFile(path);
            
            var diskName = "Workbench";
            var partitionBlock = rigidDiskBlock.PartitionBlocks.First();

            await using var stream = File.Open(path, FileMode.Open, FileAccess.ReadWrite);
            
            await Format.Pfs3Format(stream, partitionBlock, diskName);
        }
        
        [Fact(Skip = "Manually used for testing")]
        public async Task WhenCreateBlankHdfForAmigaPfs3Formatting()
        {
            var path = @"d:\Temp\pfs3_format_amiga\pfs3_format_amiga.hdf";

            var rigidDiskBlock = RigidDiskBlock
                .Create(300.MB().ToUniversalSize())
                .AddFileSystem("PFS3", await File.ReadAllBytesAsync(@"TestData\pfs3aio"))
                .AddPartition("DH0", bootable: true);
            //.WriteToFile(path);
            var partitionBlock = rigidDiskBlock.PartitionBlocks.First();
            await using var stream = File.OpenRead(path);
        }
        
        [Fact(Skip = "Manually used for testing")]
        public async Task Dump()
        {
            var stream = File.OpenRead(@"d:\Temp\4gb_amigaos_39_install\4gb.hdf");
            stream.Seek(63 * 2 * 16 * 512, SeekOrigin.Begin);

            var bytes = await stream.ReadBytes(1024 * 1024);
            await File.WriteAllBytesAsync(@"d:\Temp\4gb_amigaos_39_install\part1.bin", bytes);
        }
        
        [Fact]
        public async Task DumpUsedSectors()
        {
            var options = (RootBlock.DiskOptionsEnum)1919;
            
            // var path = @"d:\Temp\pfs3_format_amiga\pfs3_format_amiga.hdf";
            var path = @"d:\Temp\pfs3_format_hstwb\pfs3_format_hstwb.hdf";
            var dir = Path.GetDirectoryName(path);
            
            await using var stream = File.OpenRead(path);
            var dataSectorReader = new DataSectorReader(stream);

            SectorResult sectorResult;
            do
            {
                sectorResult = await dataSectorReader.ReadNext();
                foreach (var sector in sectorResult.Sectors.Where(x => !x.IsZeroFilled))
                {
                    await File.WriteAllBytesAsync(Path.Combine(dir, $"sector_{sector.Start:D10}.bin"), sector.Data);
                }
            } while (!sectorResult.EndOfSectors);
        }
    }
}