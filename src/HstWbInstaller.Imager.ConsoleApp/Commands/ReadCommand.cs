namespace HstWbInstaller.Imager.ConsoleApp.Commands
{
    using System;
    using System.Collections.Generic;
    using System.IO;
    using System.Linq;
    using System.Threading.Tasks;
    using Core;

    public class ReadCommand : CommandBase
    {
        public override async Task Execute(IEnumerable<IPhysicalDrive> physicalDrives, Arguments arguments)
        {
            Console.WriteLine("Reading physical drive to image file");
            
            if (string.IsNullOrWhiteSpace(arguments.Src))
            {
                await Console.Error.WriteLineAsync("No source");
                return;
            }

            var srcPhysicalDrive =
                physicalDrives.FirstOrDefault(x => x.Path.Equals(arguments.Src, StringComparison.OrdinalIgnoreCase));

            if (srcPhysicalDrive == null)
            {
                await Console.Error.WriteLineAsync($"No physical drive with source '{arguments.Src}'");
                return;
            }

            if (string.IsNullOrWhiteSpace(arguments.Dest))
            {
                await Console.Error.WriteLineAsync("No destination");
                return;
            }

            Console.WriteLine($"Source: {arguments.Src}");
            Console.WriteLine($"Destination: {arguments.Dest}");
            
            var destDir = Path.GetDirectoryName(arguments.Dest);

            if (!string.IsNullOrEmpty(destDir) && !Directory.Exists(destDir))
            {
                Directory.CreateDirectory(destDir);
            }

            var skipZeroFilled = arguments.Dest.EndsWith(".vhd", StringComparison.OrdinalIgnoreCase);

            await using var srcStream = srcPhysicalDrive.Open();
            await using var destStream = File.Open(arguments.Dest, FileMode.Create, FileAccess.ReadWrite);

            var size = srcPhysicalDrive.RigidDiskBlock?.DiskSize ?? srcPhysicalDrive.Size;            
            var imageConverter = new ImageConverter();
            
            var bytesConverted = 0L;
            imageConverter.DataConverted += (o, e) =>
            {
                var pct = bytesConverted == 0 ? 0 : (double)100 / size * bytesConverted;
                Console.WriteLine($"{pct} ({bytesConverted} / {size} bytes)");
            };
            await imageConverter.Convert(srcStream, destStream, size, skipZeroFilled);
            
            Console.WriteLine("Done");
        }
    }
}