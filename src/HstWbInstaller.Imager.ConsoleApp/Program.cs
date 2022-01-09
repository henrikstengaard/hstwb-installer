namespace HstWbInstaller.Imager.ConsoleApp
{
    using System;
    using System.CommandLine;
    using System.CommandLine.Invocation;
    using System.CommandLine.IO;
    using System.CommandLine.Parsing;
    using System.CommandLine.Binding;
    using System.CommandLine.Builder;
    using System.CommandLine.Invocation;
    using System.CommandLine.Parsing;
    using System.IO;
    using System.Linq;
    using System.Text.Json;
    using System.Threading.Tasks;
    using HstWbInstaller.Core.IO.RigidDiskBlocks;
    using Core;
    using HstWbInstaller.Core.IO.Vhds;
    using PhysicalDrives;

    class Program
    {
        static async Task<int> Main(string[] args)
        {
            var listDrivesOption = new Option<bool>(
                new[] { "--list-drives", "-l" },
                "List physical drives.");
            var srcOption = new Option<string>(
                new[] { "--src", "-s" },
                "Source image file or physical drive.");
            var destOption = new Option<string>(
                new[] { "--dest", "-d" },
                "Destination image file or physical drive.");
            var fakeOption = new Option<bool>(
                new[] { "--fake", "-f" },
                "Fake physical drives (debug only).");

            var rootCommand = new RootCommand
            {
                listDrivesOption,
                srcOption,
                destOption,
                fakeOption
            };
            rootCommand.Description = "HstWB Installer Imager to read and write image file to and from physical drive.";
            rootCommand.SetHandler(
                async (bool listDrives, string src, string dest, bool fake) =>
                {
                    await Main(listDrives, src, dest, fake);
                }, listDrivesOption, srcOption, destOption, fakeOption);
            return await rootCommand.InvokeAsync(args);

            // -s disk1 -d hello.vhd

            var fake = args.Any(x => x.Equals("-fake", StringComparison.OrdinalIgnoreCase));
            var windows = args.Any(x => x.Equals("-windows", StringComparison.OrdinalIgnoreCase));
            var linux = args.Any(x => x.Equals("-linux", StringComparison.OrdinalIgnoreCase));

            var list = args.Any(x => x.Equals("-linux", StringComparison.OrdinalIgnoreCase));

            // using (var src = File.OpenRead(@"D:\Temp\4gb_testing2\4gb.hdf"))
            // {
            //     using (var dst = File.OpenWrite(@"test.hdf"))
            //     {
            //         var buffer = new byte[512 * 16];
            //
            //         var bytesRead = src.Read(buffer, 0, buffer.Length);
            //         
            //         dst.Write(buffer, 0, bytesRead);
            //     }
            // }
            IPhysicalDriveManager physicalDriveManager;

            if (windows || OperatingSystem.IsWindows())
            {
                physicalDriveManager = new WindowsPhysicalDriveManager(fake);
            }
            else if (linux || OperatingSystem.IsLinux())
            {
                physicalDriveManager = new LinuxPhysicalDriveManager(fake);
            }
            else
            {
                throw new NotImplementedException("Unsupported operating system");
            }

            var physicalDrives = (await physicalDriveManager.GetPhysicalDrives()).ToList();
            Console.WriteLine(JsonSerializer.Serialize(physicalDrives));

            return 0;

            foreach (var physicalDrive in physicalDrives)
            {
                Console.WriteLine(physicalDrive.Path);
                var buffer = new byte[8192];

                try
                {
                    await using var stream = physicalDrive.Open();
                    var position = stream.Seek(0, SeekOrigin.Begin);
                    await stream.ReadAsync(buffer, 0, buffer.Length);
                }
                catch (Exception e)
                {
                    Console.WriteLine(
                        $"Failed to read first {buffer.Length} bytes from physical drive '{physicalDrive.Path}': {e}");
                    throw;
                }

                await File.WriteAllBytesAsync(physicalDrive.Path.Replace("\\", ""), buffer);

                try
                {
                    var rigidDiskBlockReader = new RigidDiskBlockReader(new MemoryStream(buffer));

                    var rigidDiskBlock = await rigidDiskBlockReader.Read(false);

                    if (rigidDiskBlock != null)
                    {
                        Console.WriteLine(JsonSerializer.Serialize(rigidDiskBlock));
                    }
                }
                catch (Exception e)
                {
                    Console.WriteLine($"Failed to rdb from physical drive '{physicalDrive.Path}': {e}");
                }
            }
        }

        private static JsonSerializerOptions jsonSerializerOptions = new JsonSerializerOptions
        {
            WriteIndented = true
        };

        static async Task Main(bool listDrives, string src, string dest, bool fake)
        {
            IPhysicalDriveManager physicalDriveManager;

            if (OperatingSystem.IsWindows())
            {
                physicalDriveManager = new WindowsPhysicalDriveManager(fake);
            }
            else if (OperatingSystem.IsLinux())
            {
                physicalDriveManager = new LinuxPhysicalDriveManager(fake);
            }
            else
            {
                throw new NotImplementedException("Unsupported operating system");
            }

            var physicalDrives = (await physicalDriveManager.GetPhysicalDrives()).ToList();

            var buffer = new byte[8192];
            foreach (var physicalDrive in physicalDrives)
            {
                try
                {
                    await using var stream = physicalDrive.Open();
                    var position = stream.Seek(0, SeekOrigin.Begin);
                    await stream.ReadAsync(buffer, 0, buffer.Length);
                }
                catch (Exception e)
                {
                    Console.WriteLine(
                        $"Failed to read first {buffer.Length} bytes from physical drive '{physicalDrive.Path}': {e}");
                }

                try
                {
                    var rigidDiskBlockReader = new RigidDiskBlockReader(new MemoryStream(buffer));

                    physicalDrive.RigidDiskBlock = await rigidDiskBlockReader.Read(false);
                }
                catch (Exception e)
                {
                    Console.WriteLine($"Failed to rigid disk block from physical drive '{physicalDrive.Path}': {e}");
                }
            }

            if (listDrives)
            {
                Console.WriteLine(JsonSerializer.Serialize(physicalDrives, jsonSerializerOptions));
                return;
            }

            if (string.IsNullOrWhiteSpace(src))
            {
                await Console.Error.WriteLineAsync("No src");
                return;
            }

            if (string.IsNullOrWhiteSpace(dest))
            {
                await Console.Error.WriteLineAsync("No dest");
                return;
            }

            Console.WriteLine("Source: {src}");
            Console.WriteLine("Destination: {dest}");

            var srcPhysicalDrive =
                physicalDrives.FirstOrDefault(x => x.Path.Equals(src, StringComparison.OrdinalIgnoreCase));
            await using var srcStream = srcPhysicalDrive == null ? File.OpenRead(src) : srcPhysicalDrive.Open();
            var destPhysicalDrive =
                physicalDrives.FirstOrDefault(x => x.Path.Equals(dest, StringComparison.OrdinalIgnoreCase));
            await using var destStream = destPhysicalDrive == null
                ? File.Open(dest, FileMode.Create, FileAccess.ReadWrite)
                : destPhysicalDrive.Open();

            ulong srcSize;
            if (srcPhysicalDrive != null)
            {
                srcSize = srcPhysicalDrive.RigidDiskBlock?.DiskSize ?? srcPhysicalDrive.Size;
            }
            else
            {
                srcSize = Convert.ToUInt64(srcStream.Length);
            }

            Console.WriteLine($"{srcSize} bytes");

            ulong totalBytesRead = 0;

            if (dest.EndsWith(".vhd"))
            {
                Console.WriteLine("Vhd");
                var vhd = new VhdConverter();
                vhd.DataTransferred += (o, e) =>
                {
                    if (e.BytesTransferred == 0)
                    {
                        return;
                    }
                    totalBytesRead += (ulong)e.BytesTransferred;
                    var pct = totalBytesRead == 0 ? 0 : ((double)100 / srcSize) * totalBytesRead;
                    Console.WriteLine($"{pct} ({ totalBytesRead } / {srcSize})");
                };
                await vhd.ConvertImgToVhd(srcStream, destStream, Convert.ToInt64(srcSize));
                Console.WriteLine($"Done");
                return;
            }

            Console.WriteLine("Img");
            buffer = new byte[1024 * 1024];
            int bytesRead;
            do
            {
                bytesRead = await srcStream.ReadAsync(buffer, 0, buffer.Length);
                totalBytesRead += (ulong)bytesRead;
                await destStream.WriteAsync(buffer, 0, bytesRead);

                var pct = totalBytesRead == 0 ? 0 : ((double)100 / srcSize) * totalBytesRead;
                Console.WriteLine($"{pct}");
            } while (bytesRead == buffer.Length);

            Console.WriteLine($"Done");
        }
    }
}