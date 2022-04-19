namespace HstWbInstaller.Core.Tests.Pfs3Tests
{
    using System;
    using System.IO;
    using System.Linq;
    using System.Text;
    using System.Threading.Tasks;
    using Extensions;
    using IO.Pfs3;
    using IO.RigidDiskBlocks;
    using IO.Vhds;
    using Xunit;
    using Directory = System.IO.Directory;

    public class GivenPfs3BlockHelper
    {
        [Fact(Skip = "Manually used for testing")]
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
        
        [Fact(Skip = "Manually used for testing")]
        public async Task DumpUsedSectors()
        {
            //var options = (RootBlock.DiskOptionsEnum)1919;
            
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

        [Fact(Skip = "Manually used for testing")]
        public async Task CompareSectors()
        {
            var outputBuilder = new StringBuilder();
            
            var sourcePath = @"d:\Temp\pfs3_format_amiga";
            var destinationPath = @"d:\Temp\pfs3_format_hstwb";

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
            
            outputBuilder.AppendLine($"Id = '{string.Join(string.Empty, idBytes.Select(x => x.ToString("x2"))).ToUpper()}' ({id})");
            outputBuilder.AppendLine($"Compare '{sourcePath}' ({sourceBytes.Length}) <> '{destinationPath}' ({destinationBytes.Length})");
            outputBuilder.AppendLine();
        }
    }
}