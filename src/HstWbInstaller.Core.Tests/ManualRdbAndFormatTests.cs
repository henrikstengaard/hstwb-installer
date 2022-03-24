namespace HstWbInstaller.Core.Tests
{
    using System.Collections.Generic;
    using System.IO;
    using System.Linq;
    using System.Threading.Tasks;
    using Extensions;
    using IO.FastFileSystem;
    using IO.RigidDiskBlocks;
    using IO.Vhds;
    using Xunit;

    public class ManualRdbAndFormatTests
    {
        [Fact(Skip = "Manual test")]
        public async Task WhenCreateAndWriteRigidDiskBlockThenRigidDiskBlockIsEqual()
        {
            // await using var stream = File.OpenRead(@"d:\temp\partitioned_with_hdtoolbox.hdf");
            // var actualRigidDiskBlock = await RigidDiskBlockReader.Read(stream);
            
            
            var path = @"d:\temp\partitioned_with_hstwb.hdf";

            var reserved = 2; // beginning of partition
            var lowCyl = 2;
            var highCyl = 91;
            var cylinders = highCyl - lowCyl + 1;
            var highKey = cylinders * 16 * 63 - 1;
            var rootKey = (reserved + highKey) / 2;
            var rootOffset = rootKey * 512;
            
            var partitionOffset = lowCyl * 16 * 63 * 512;
            var rootBlockOffset = partitionOffset + rootOffset;

            await using var stream = File.OpenRead(path);
            stream.Position = partitionOffset;
            var dataSectorReader = new DataSectorReader(stream);

            var sectors = new List<Sector>();
            SectorResult sectorResult;
            do
            {
                sectorResult = await dataSectorReader.ReadNext();

                var dataSectors = sectorResult.Sectors.Where(x => x.Data.Any(b => b != 0)).ToList();
                if (!dataSectors.Any())
                {
                    continue;
                }
                
                sectors.AddRange(dataSectors);
            } while (!sectorResult.EndOfSectors);

            foreach (var sector in sectors)
            {
                await File.WriteAllBytesAsync($"{sector.Start}_block.bin", sector.Data);
            }
            
            // var size = 47480832;
            // var rigidDiskBlock = await RigidDiskBlock
            //     .Create(size)
            //     .AddFileSystem("DOS3", await File.ReadAllBytesAsync(@"d:\Temp\4gb\pc\hdtoolbox_wb31_uae\FastFileSystem"))
            //     .AddPartition("DH0", bootable: true)
            //     .WriteToFile(@"d:\temp\partitioned_with_hstwb.hdf");

            // await using (var hdfStream = File.OpenWrite(@"d:\temp\partitioned_with_hdtoolbox.hdf"))
            // {
            //     hdfStream.SetLength(size);
            // }
            //
            // await using var stream = File.OpenRead(path);
            // var actualRigidDiskBlock = await RigidDiskBlockReader.Read(stream);
            //
            // var rigidDiskBlockJson = System.Text.Json.JsonSerializer.Serialize(rigidDiskBlock);
            // var actualRigidDiskBlockJson = System.Text.Json.JsonSerializer.Serialize(actualRigidDiskBlock);
            // Assert.Equal(rigidDiskBlockJson,actualRigidDiskBlockJson);
        }

        [Fact(Skip = "Manual test")]
        public async Task Format()
        {
            var size = 47480832;
            var rigidDiskBlock = await RigidDiskBlock
                .Create(size)
                .AddFileSystem("DOS3", await File.ReadAllBytesAsync(@"d:\Temp\4gb\pc\hdtoolbox_wb31_uae\FastFileSystem"))
                .AddPartition("DH0", bootable: true)
                .WriteToFile(@"d:\temp\partitioned_formatted_with_hstwb.hdf");

            await using var stream = File.OpenWrite(@"d:\temp\partitioned_formatted_with_hstwb.hdf");
            await stream.FormatFastFileSystem(rigidDiskBlock.PartitionBlocks.First(), "WorkbenchHstWB");
        }

        private async Task DumpDataSectors(string path, long offset = 0)
        {
            await using var stream = File.OpenRead(path);
            stream.Position = offset;
            var dataSectorReader = new DataSectorReader(stream);

            var sectors = new List<Sector>();
            SectorResult sectorResult;
            do
            {
                sectorResult = await dataSectorReader.ReadNext();

                var dataSectors = sectorResult.Sectors.Where(x => x.Data.Any(b => b != 0)).ToList();
                if (!dataSectors.Any())
                {
                    continue;
                }
                
                sectors.AddRange(dataSectors);
            } while (!sectorResult.EndOfSectors);

            foreach (var sector in sectors)
            {
                await File.WriteAllBytesAsync($"{sector.Start}_block.bin", sector.Data);
            }
        }

        private BitmapBlock CreateBitmapBlock(int cylinders, int blockSize)
        {
            var blocksPerLongDatatype = 32;
            var size = blockSize - 4;

            var bitmapBlock = new BitmapBlock
            {
                BlockFree = new bool[size * blocksPerLongDatatype]
            };

            for (var i = 0; i < bitmapBlock.BlockFree.Length; i++)
            {
                bitmapBlock.BlockFree[i] = true;
            }

            return bitmapBlock;
        }
        
    }
}