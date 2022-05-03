namespace HstWbInstaller.Core.Tests.Pfs3Tests
{
    using System;
    using System.IO;
    using System.Linq;
    using System.Text;
    using System.Threading.Tasks;
    using Extensions;
    using IO.Pfs3;
    using IO.Pfs3.Blocks;
    using IO.RigidDiskBlocks;
    using IO.Vhds;
    using Xunit;
    using Directory = System.IO.Directory;

    public class GivenPfs3BlockHelper
    {
        [Fact(Skip = "Manually used for testing")]
        public async Task When()
        {
            var path = @"d:\Temp\pfs3_format_hstwb\pfs3_format_hstwb.hdf";
            
            await using var stream = File.Open(path, FileMode.Open, FileAccess.ReadWrite);

            var rigidDiskBlock = await RigidDiskBlockReader.Read(stream);
            
            var partitionBlock = rigidDiskBlock.PartitionBlocks.First();

            var globalData = Init.CreateGlobalData(partitionBlock.Sectors, partitionBlock.BlocksPerTrack,
                partitionBlock.Surfaces, partitionBlock.LowCyl, partitionBlock.HighCyl, partitionBlock.NumBuffer,
                partitionBlock.FileSystemBlockSize);
            globalData.stream = stream;
            
            var rootBlock = await ReadRootBlock(@"d:\Temp\pfs3_format_hstwb\sector_0001033216.bin");

            var reservedBitmapBlockBytes1 = await File.ReadAllBytesAsync(@"d:\Temp\pfs3_format_hstwb\sector_0001033728.bin");
            var reservedBitmapBlockBytes2 = await File.ReadAllBytesAsync(@"d:\Temp\pfs3_format_hstwb\sector_0001034240.bin");
            var reservedBitmapBlock =
                await BitmapBlockReader.Parse(reservedBitmapBlockBytes1.Concat(reservedBitmapBlockBytes2).ToArray(), globalData);
            rootBlock.ReservedBitmapBlock = reservedBitmapBlock;
            
            globalData.RootBlock = rootBlock;
            globalData.currentvolume = await Volume.MakeVolumeData(rootBlock, globalData);
            globalData.glob_allocdata.res_bitmap = reservedBitmapBlock;
            
            // loop all allocated blocks according to reserved bitmap block
            
            // await Init.InitModules(globalData.currentvolume, false, globalData);
            
            var dirBlock = await ReadDirBlock(@"d:\Temp\pfs3_format_hstwb\sector_0001116160.bin", globalData);
            
            //var path = @"d:\Temp\pfs3_format_hstwb\sector_0001112064.bin";
            // var bytes = await File.ReadAllBytesAsync(path);
            // var block = await RootBlockExtensionReader.Parse(bytes);
        }

        private async Task<RootBlock> ReadRootBlock(string path)
        {
            var bytes = await File.ReadAllBytesAsync(path);
            return await RootBlockReader.Parse(bytes);
        }
        
        private async Task<dirblock> ReadDirBlock(string path, globaldata g)
        {
            var bytes = await File.ReadAllBytesAsync(path);
            return await DirBlockReader.Parse(bytes, g);
        }

        [Fact(Skip = "Manually used for testing")]
        public async Task WhenCreateHdfWithPfs3FormattedUsingHstWb()
        {
            var path = @"d:\Temp\pfs3_format_hstwb\pfs3_format_hstwb.hdf";

            // var rigidDiskBlock = await RigidDiskBlock
            //     .Create(300.MB().ToUniversalSize())
            //     .AddFileSystem("PFS3", await File.ReadAllBytesAsync(@"TestData\pfs3aio"))
            //     .AddPartition("DH0", bootable: true)
            //     .WriteToFile(path);
            //
            // var diskName = "Formatted With HstWB Imager";
            // var partitionBlock = rigidDiskBlock.PartitionBlocks.First();
            //
            // await using var stream = File.Open(path, FileMode.Open, FileAccess.ReadWrite);
            //
            // await Pfs3Formatter.FormatPartition(stream, partitionBlock, diskName);
            // stream.Close();
            // await stream.DisposeAsync();
            
            await DumpUsedSectors(path);
            //
            // var sourcePath = @"d:\Temp\pfs3_format_amiga";
            // var destinationPath = @"d:\Temp\pfs3_format_hstwb";
            //
            // await CompareSectors(sourcePath, destinationPath);
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
        
        public async Task DumpUsedSectors(string path)
        {
            //var options = (RootBlock.DiskOptionsEnum)1919;
            
            // var path = @"d:\Temp\pfs3_format_amiga\pfs3_format_amiga.hdf";
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

        public async Task CompareSectors(string sourcePath, string destinationPath)
        {
            var outputBuilder = new StringBuilder();
            
            var sourceBinFiles = Directory.GetFiles(sourcePath, "*.bin");
            foreach (var sourceBinFile in sourceBinFiles)
            {
                var destinationBinFile = Path.Combine(destinationPath, Path.GetFileName(sourceBinFile));
                if (!File.Exists(destinationBinFile))
                {
                    outputBuilder.AppendLine($"Destination file '{destinationBinFile}' not found matching source");
                    continue;
                }

                await Compare(sourceBinFile, destinationBinFile, outputBuilder);
            }

            var destinationBinFiles = Directory.GetFiles(destinationPath, "*.bin");
            foreach (var destinationBinFile in destinationBinFiles)
            {
                var sourceBinFile = Path.Combine(sourcePath, Path.GetFileName(destinationBinFile));
                if (!File.Exists(sourceBinFile))
                {
                    outputBuilder.AppendLine($"Source file '{sourceBinFile}' not found matching destination");
                }
            }

            await File.WriteAllTextAsync(@"d:\Temp\pfs3_format_hstwb\sector_compare.txt", outputBuilder.ToString());
        }

        private async Task Compare(string sourcePath, string destinationPath, StringBuilder outputBuilder)
        {
            var sourceBytes = await File.ReadAllBytesAsync(sourcePath);
            var destinationBytes = await File.ReadAllBytesAsync(destinationPath);
                
            var isEqual = sourceBytes.Length == destinationBytes.Length;

            var idBytes = new byte[2];
            Array.Copy(sourceBytes, 0, idBytes, 0, 2);
            var id = Encoding.ASCII.GetString(idBytes);
            
            for (var i = 0; i < sourceBytes.Length && i < destinationBytes.Length; i++)
            {
                var sourceByte = sourceBytes[i];
                var destinationByte = destinationBytes[i];

                if (sourceByte == destinationByte)
                {
                    continue;
                }

                outputBuilder.AppendLine($"Offset '0x{i.ToString("x2").ToUpper()}' ({i}) is not equal: '0x{sourceByte.ToString("x2").ToUpper()}' ({sourceByte}) <> '0x{destinationByte.ToString("x2").ToUpper()}' ({destinationByte})");
                isEqual = false;
            }

            if (isEqual)
            {
                return;
            }
            
            outputBuilder.AppendLine($"Id = '0x{string.Join(string.Empty, idBytes.Select(x => x.ToString("x2"))).ToUpper()}' ({id})");
            outputBuilder.AppendLine($"Compare '{sourcePath}' ({sourceBytes.Length}) <> '{destinationPath}' ({destinationBytes.Length})");
            outputBuilder.AppendLine();
        }
    }
}