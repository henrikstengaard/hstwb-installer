namespace HstWbInstaller.Core.Tests.FastFileSystemTests
{
    using System;
    using System.IO;
    using System.Linq;
    using System.Text;
    using System.Threading.Tasks;
    using IO.Vhds;

    public static class TestHelper
    {
        public static async Task DumpUsedSectors(string path, string outputPath)
        {
            if (!System.IO.Directory.Exists(outputPath))
            {
                System.IO.Directory.CreateDirectory(outputPath);
            }
            
            await using var stream = System.IO.File.OpenRead(path);
            var dataSectorReader = new DataSectorReader(stream);

            SectorResult sectorResult;
            do
            {
                sectorResult = await dataSectorReader.ReadNext();
                foreach (var sector in sectorResult.Sectors.Where(x => !x.IsZeroFilled))
                {
                    await System.IO.File.WriteAllBytesAsync(Path.Combine(outputPath,$"sector_{sector.Start:D10}.bin"), sector.Data);
                }
            } while (!sectorResult.EndOfSectors);
        }
        
        public static async Task CompareSectors(string sourcePath, string destinationPath)
        {
            var outputBuilder = new StringBuilder();
            
            var sourceBinFiles = System.IO.Directory.GetFiles(sourcePath, "*.bin");
            foreach (var sourceBinFile in sourceBinFiles)
            {
                var destinationBinFile = Path.Combine(destinationPath, Path.GetFileName(sourceBinFile));
                if (!System.IO.File.Exists(destinationBinFile))
                {
                    outputBuilder.AppendLine($"Destination file '{destinationBinFile}' not found matching source");
                    continue;
                }

                await Compare(sourceBinFile, destinationBinFile, outputBuilder);
            }

            var destinationBinFiles = System.IO.Directory.GetFiles(destinationPath, "*.bin");
            foreach (var destinationBinFile in destinationBinFiles)
            {
                var sourceBinFile = Path.Combine(sourcePath, Path.GetFileName(destinationBinFile));
                if (!System.IO.File.Exists(sourceBinFile))
                {
                    outputBuilder.AppendLine($"Source file '{sourceBinFile}' not found matching destination");
                }
            }

            await System.IO.File.WriteAllTextAsync(@"sector_compare.txt", outputBuilder.ToString());
        }

        public static async Task Compare(string sourcePath, string destinationPath, StringBuilder outputBuilder)
        {
            var sourceBytes = await System.IO.File.ReadAllBytesAsync(sourcePath);
            var destinationBytes = await System.IO.File.ReadAllBytesAsync(destinationPath);
                
            var idBytes = new byte[2];
            Array.Copy(sourceBytes, 0, idBytes, 0, 2);
            var id = Encoding.ASCII.GetString(idBytes);
            
            outputBuilder.Append(Compare(sourceBytes, destinationBytes));
            
            // outputBuilder.AppendLine($"Id = '0x{string.Join(string.Empty, idBytes.Select(x => x.ToString("x2"))).ToUpper()}' ({id})");
            outputBuilder.AppendLine($"Compare '{sourcePath}' ({sourceBytes.Length}) <> '{destinationPath}' ({destinationBytes.Length})");
            outputBuilder.AppendLine();
        }
        
        public static string Compare(byte[] sourceBytes, byte[] destinationBytes)
        {
            var outputBuilder = new StringBuilder();
            
            var isEqual = sourceBytes.Length == destinationBytes.Length;

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

            return isEqual ? string.Empty : outputBuilder.ToString();
        }
    }
}