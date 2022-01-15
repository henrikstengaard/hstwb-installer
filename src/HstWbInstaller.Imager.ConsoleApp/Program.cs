namespace HstWbInstaller.Imager.ConsoleApp
{
    using System;
    using System.Collections.Generic;
    using System.CommandLine;
    using System.IO;
    using System.Linq;
    using System.Threading.Tasks;
    using Commands;
    using HstWbInstaller.Core.IO.RigidDiskBlocks;
    using Core;
    using PhysicalDrives;

    class Program
    {
        static async Task<int> Main(string[] args)
        {
            var listOption = new Option<bool>(
                new[] { "--list", "-l" },
                "List physical drives.");
            var infoOption = new Option<bool>(
                new[] { "--info", "-i" },
                "Display information about physical drive or image file.");
            var readOption = new Option<bool>(
                new[] { "--read", "-r" },
                "Read physical drive to image file.");
            var writeOption = new Option<bool>(
                new[] { "--write", "-w" },
                "Write image file to physical drive.");
            var convertOption = new Option<bool>(
                new[] { "--convert", "-c" },
                "Convert image file.");
            var verifyOption = new Option<bool>(
                new[] { "--verify", "-v" },
                "Convert image file.");
            var blankOption = new Option<bool>(
                new[] { "--blank", "-b" },
                "Create blank image file.");
            var optimizeOption = new Option<bool>(
                new[] { "--optimize", "-o" },
                "Optimize image file.");
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
                listOption,
                infoOption,
                readOption,
                writeOption,
                convertOption,
                verifyOption,
                blankOption,
                optimizeOption,
                srcOption,
                destOption,
                fakeOption
            };
            rootCommand.Description = "HstWB Installer Imager to read and write image file to and from physical drive.";
            rootCommand.SetHandler(
                async (bool list, bool info, bool read, bool write, bool convert, bool verify, bool blank, bool optimize, string src,
                    string dest, bool fake) =>
                {
                    Arguments.CommandEnum command = Arguments.CommandEnum.None;
                    if (list)
                    {
                        command = Arguments.CommandEnum.List;
                    }
                    else if (info)
                    {
                        command = Arguments.CommandEnum.Info;
                    }
                    else if (read)
                    {
                        command = Arguments.CommandEnum.Read;
                    }
                    else if (write)
                    {
                        command = Arguments.CommandEnum.Write;
                    }
                    else if (convert)
                    {
                        command = Arguments.CommandEnum.Convert;
                    }
                    else if (verify)
                    {
                        command = Arguments.CommandEnum.Verify;
                    }
                    else if (blank)
                    {
                        command = Arguments.CommandEnum.Blank;
                    }
                    else if (optimize)
                    {
                        command = Arguments.CommandEnum.Optimize;
                    }
                    
                    await Main(new Arguments
                    {
                        Command = command,
                        Src = src,
                        Dest = dest,
                        Fake = fake
                    });
                }, listOption, infoOption, readOption, writeOption, convertOption, verifyOption, blankOption, optimizeOption,
                srcOption, destOption, fakeOption);
            return await rootCommand.InvokeAsync(args);

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
            // IPhysicalDriveManager physicalDriveManager;
            //
            // if (windows || OperatingSystem.IsWindows())
            // {
            //     physicalDriveManager = new WindowsPhysicalDriveManager(fake);
            // }
            // else if (linux || OperatingSystem.IsLinux())
            // {
            //     physicalDriveManager = new LinuxPhysicalDriveManager(fake);
            // }
            // else
            // {
            //     throw new NotImplementedException("Unsupported operating system");
            // }
            //
            // var physicalDrives = (await physicalDriveManager.GetPhysicalDrives()).ToList();
            // Console.WriteLine(JsonSerializer.Serialize(physicalDrives));
            //
            // return 0;
            //
            // foreach (var physicalDrive in physicalDrives)
            // {
            //     Console.WriteLine(physicalDrive.Path);
            //     var buffer = new byte[8192];
            //
            //     try
            //     {
            //         await using var stream = physicalDrive.Open();
            //         var position = stream.Seek(0, SeekOrigin.Begin);
            //         await stream.ReadAsync(buffer, 0, buffer.Length);
            //     }
            //     catch (Exception e)
            //     {
            //         Console.WriteLine(
            //             $"Failed to read first {buffer.Length} bytes from physical drive '{physicalDrive.Path}': {e}");
            //         throw;
            //     }
            //
            //     await File.WriteAllBytesAsync(physicalDrive.Path.Replace("\\", ""), buffer);
            //
            //     try
            //     {
            //         var rigidDiskBlockReader = new RigidDiskBlockReader(new MemoryStream(buffer));
            //
            //         var rigidDiskBlock = await rigidDiskBlockReader.Read(false);
            //
            //         if (rigidDiskBlock != null)
            //         {
            //             Console.WriteLine(JsonSerializer.Serialize(rigidDiskBlock));
            //         }
            //     }
            //     catch (Exception e)
            //     {
            //         Console.WriteLine($"Failed to rdb from physical drive '{physicalDrive.Path}': {e}");
            //     }
            // }
        }

        // private static JsonSerializerOptions jsonSerializerOptions = new JsonSerializerOptions
        // {
        //     WriteIndented = true
        // };
        //
        static async Task Main(Arguments arguments)
        {
            IPhysicalDriveManager physicalDriveManager;

            if (OperatingSystem.IsWindows())
            {
                physicalDriveManager = new WindowsPhysicalDriveManager(arguments.Fake);
            }
            else if (OperatingSystem.IsLinux())
            {
                physicalDriveManager = new LinuxPhysicalDriveManager(arguments.Fake);
            }
            else
            {
                throw new NotImplementedException("Unsupported operating system");
            }

            var physicalDrives = (await physicalDriveManager.GetPhysicalDrives()).ToList();
            if (arguments.Command == Arguments.CommandEnum.List ||
                arguments.Command == Arguments.CommandEnum.Read ||
                arguments.Command == Arguments.CommandEnum.Write)
            {
                await ReadRigidDiskBlocks(physicalDrives);
            }

            switch (arguments.Command)
            {
                case Arguments.CommandEnum.Info:
                    await new ListCommand().Execute(physicalDrives, arguments);
                    break;
                case Arguments.CommandEnum.Read:
                    await new ReadCommand().Execute(physicalDrives, arguments);
                    break;
            }
            
            // var srcPhysicalDrive =
            //     physicalDrives.FirstOrDefault(x => x.Path.Equals(src, StringComparison.OrdinalIgnoreCase));
            // await using var srcStream = srcPhysicalDrive == null ? File.OpenRead(src) : srcPhysicalDrive.Open();
            // var destPhysicalDrive =
            //     physicalDrives.FirstOrDefault(x => x.Path.Equals(dest, StringComparison.OrdinalIgnoreCase));
            // await using var destStream = destPhysicalDrive == null
            //     ? File.Open(dest, FileMode.Create, FileAccess.ReadWrite)
            //     : destPhysicalDrive.Open();
            //
            // if (srcPhysicalDrive == null &&
            //     destPhysicalDrive == null &&
            //     src.Equals(dest, StringComparison.OrdinalIgnoreCase))
            // {
            //     Console.WriteLine("Trim");
            // }
            //
            // Console.WriteLine("Source: {src}");
            // Console.WriteLine("Destination: {dest}");
            //
            // ulong srcSize;
            // if (srcPhysicalDrive != null)
            // {
            //     srcSize = srcPhysicalDrive.RigidDiskBlock?.DiskSize ?? srcPhysicalDrive.Size;
            // }
            // else
            // {
            //     srcSize = Convert.ToUInt64(srcStream.Length);
            // }
            //
            // Console.WriteLine($"{srcSize} bytes");
            //
            // ulong bytesWritten = 0;
            //
            // if (dest.EndsWith(".vhd"))
            // {
            //     Console.WriteLine("Vhd");
            //     var vhd = new VhdConverter();
            //     vhd.DataTransferred += (o, e) =>
            //     {
            //         if (e.BytesTransferred == 0)
            //         {
            //             return;
            //         }
            //
            //         bytesWritten += (ulong)e.BytesTransferred;
            //         var pct = bytesWritten == 0 ? 0 : ((double)100 / srcSize) * bytesWritten;
            //         Console.WriteLine($"{pct} ({bytesWritten} / {srcSize})");
            //     };
            //     await vhd.ConvertImgToVhd(srcStream, destStream, Convert.ToInt64(srcSize));
            //     Console.WriteLine($"Done");
            //     return;
            // }
            //
            // Console.WriteLine("Img");
            // buffer = new byte[1024 * 1024];
            // int bytesRead;
            // do
            // {
            //     bytesRead = await srcStream.ReadAsync(buffer, 0, buffer.Length);
            //     bytesWritten += (ulong)bytesRead;
            //     await destStream.WriteAsync(buffer, 0, bytesRead);
            //
            //     var pct = bytesWritten == 0 ? 0 : ((double)100 / srcSize) * bytesWritten;
            //     Console.WriteLine($"{pct}");
            // } while (bytesRead == buffer.Length);
            //
            // Console.WriteLine($"Done");
        }

        static async Task ReadRigidDiskBlocks(IEnumerable<IPhysicalDrive> physicalDrives)
        {
            var buffer = new byte[8192];
            foreach (var physicalDrive in physicalDrives)
            {
                try
                {
                    await using var stream = physicalDrive.Open();
                    stream.Seek(0, SeekOrigin.Begin);
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
        }
    }
}