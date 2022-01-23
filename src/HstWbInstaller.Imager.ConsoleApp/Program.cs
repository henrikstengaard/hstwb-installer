namespace HstWbInstaller.Imager.ConsoleApp
{
    using System;
    using System.Collections.Generic;
    using System.CommandLine;
    using System.Linq;
    using System.Threading.Tasks;
    using Core;
    using Core.Commands;
    using Core.PhysicalDrives;
    using Presenters;
    using OperatingSystem = Core.OperatingSystem;

    // read
    // -r "a" "d:\temp\test.vhd" -s 10000000 -f
    // convert
    // -c "d:\temp\test.vhd" "d:\temp\test.img"
    // info
    // -i "d:\Temp\16gb_pintz_and_amiga\16gb_base.hdf"
    // blnk
    // -b "d:\temp\blank.vhd" -s 32
    // https://github.com/dotnet/command-line-api/blob/72e86ec7615c0c8ecb6a13e34a5c0a97e9309909/docs/Your-first-app-with-System-CommandLine.md
    class Program
    {
        static async Task<int> Main(string[] args)
        {
            var listOption = new Option<bool>(
                new[] { "--list", "-l" },
                "List physical drives.");
            var infoOption = new Option<string>(
                new[] { "--info", "-i" },
                "Display information about physical drive or image file.")
            {
                Arity = ArgumentArity.ExactlyOne
            };
            var readOption = new Option<string[]>(
                new[] { "--read", "-r" },
                "Read physical drive to image file.")
            {
                AllowMultipleArgumentsPerToken = true,
                Arity = new ArgumentArity(2, 2)
            };
            var writeOption = new Option<string[]>(
                new[] { "--write", "-w" },
                "Write image file to physical drive.")
            {
                AllowMultipleArgumentsPerToken = true,
                Arity = new ArgumentArity(2, 2)
            };
            var convertOption = new Option<string[]>(
                new[] { "--convert", "-c" },
                "Convert image file.")
            {
                AllowMultipleArgumentsPerToken = true,
                Arity = new ArgumentArity(2, 2)
            };
            var verifyOption = new Option<string[]>(
                new[] { "--verify", "-v" },
                "Verify image file.")
            {
                AllowMultipleArgumentsPerToken = true,
                Arity = new ArgumentArity(2, 2)
            };
            var blankOption = new Option<string>(
                new[] { "--blank", "-b" },
                "Create blank image file.")
            {
                Arity = ArgumentArity.ExactlyOne
            };
            var optimizeOption = new Option<string>(
                new[] { "--optimize", "-o" },
                "Optimize image file.")
            {
                Arity = ArgumentArity.ExactlyOne
            };
            var sizeOption = new Option<long>(
                new[] { "--size", "-s" },
                "Size of source image file or physical drive.");
            var fakeOption = new Option<bool>(
                new[] { "--fake", "-f" },
                "Fake source paths (debug only).")
            {
                IsHidden = true
            };

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
                sizeOption,
                fakeOption
            };
            rootCommand.Description = "HstWB Installer Imager to read and write image file to and from physical drive.";
            rootCommand.SetHandler(
                async (bool list, string info, string[] read, string[] write, string[] convert, string[] verify,
                    string blank, string optimize, long size, bool fake) =>
                {
                    var arguments = new Arguments();
                    if (list)
                    {
                        arguments = new Arguments
                        {
                            Command = Arguments.CommandEnum.List
                        };
                    }
                    else if (!string.IsNullOrWhiteSpace(info))
                    {
                        arguments = new Arguments
                        {
                            Command = Arguments.CommandEnum.Info,
                            SourcePath = info
                        };
                    }
                    else if (read.Any())
                    {
                        arguments = new Arguments
                        {
                            Command = Arguments.CommandEnum.Read,
                            SourcePath = read[0],
                            DestinationPath = read[1]
                        };
                    }
                    else if (write.Any())
                    {
                        arguments = new Arguments
                        {
                            Command = Arguments.CommandEnum.Write,
                            SourcePath = write[0],
                            DestinationPath = write[1]
                        };
                    }
                    else if (convert.Any())
                    {
                        arguments = new Arguments
                        {
                            Command = Arguments.CommandEnum.Convert,
                            SourcePath = convert[0],
                            DestinationPath = convert[1]
                        };
                    }
                    else if (verify.Any())
                    {
                        arguments = new Arguments
                        {
                            Command = Arguments.CommandEnum.Verify,
                            SourcePath = verify[0],
                            DestinationPath = verify[1]
                        };
                    }
                    else if (!string.IsNullOrWhiteSpace(blank))
                    {
                        arguments = new Arguments
                        {
                            Command = Arguments.CommandEnum.Blank,
                            SourcePath = blank
                        };
                    }
                    else if (!string.IsNullOrWhiteSpace(optimize))
                    {
                        arguments = new Arguments
                        {
                            Command = Arguments.CommandEnum.Optimize,
                            SourcePath = optimize
                        };
                    }

                    if (size != 0)
                    {
                        arguments.Size = size;
                    }

                    arguments.Fake = fake;
                    await Run(arguments);
                }, listOption, infoOption, readOption, writeOption, convertOption, verifyOption, blankOption,
                optimizeOption,
                sizeOption, fakeOption);
            return await rootCommand.InvokeAsync(args);
        }

        static async Task<IEnumerable<IPhysicalDrive>> GetPhysicalDrives(Arguments arguments)
        {
            if (arguments.Fake)
            {
                var drives = new List<FakePhysicalDrive>();

                if (!string.IsNullOrWhiteSpace(arguments.SourcePath))
                {
                    drives.Add(new FakePhysicalDrive(arguments.SourcePath, "Fake", "Fake",
                        arguments.Size ?? 1024 * 1024));
                }

                if (!string.IsNullOrWhiteSpace(arguments.DestinationPath))
                {
                    drives.Add(new FakePhysicalDrive(arguments.DestinationPath, "Fake", "Fake",
                        arguments.Size ?? 1024 * 1024));
                }

                return drives;
            }

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

            return (await physicalDriveManager.GetPhysicalDrives()).ToList();
        }


        static async Task Run(Arguments arguments)
        {
            var isAdministrator = await OperatingSystem.IsAdministrator();

            if (!isAdministrator)
            {
                Console.WriteLine("Requires administrator rights!");
            }

            var commandHelper = new CommandHelper();
            var physicalDrives = (await GetPhysicalDrives(arguments)).ToList();
            
            switch (arguments.Command)
            {
                case Arguments.CommandEnum.List:
                    var listCommand = new ListCommand(commandHelper, physicalDrives);
                    listCommand.ListRead += (_, args) =>
                    {
                        //
                        // await Task.Run(() =>
                        // {
                        //     Console.WriteLine(JsonSerializer.Serialize(physicalDrivesList, JsonSerializerOptions));
                        // });
                        InfoPresenter.PresentInfo(args.MediaInfos);
                    };
                    await listCommand.Execute();
                    var listResult = await listCommand.Execute();
                    Console.WriteLine(listResult.IsSuccess ? "Done" : $"ERROR: Read failed, {listResult.Error}");
                    break;
                case Arguments.CommandEnum.Info:
                    var infoCommand = new InfoCommand(commandHelper, physicalDrives, arguments.SourcePath);
                    infoCommand.DiskInfoRead += (_, args) => { InfoPresenter.PresentInfo(args.MediaInfo); };
                    var infoResult = await infoCommand.Execute();
                    Console.WriteLine(infoResult.IsSuccess ? "Done" : $"ERROR: Read failed, {infoResult.Error}");
                    break;
                case Arguments.CommandEnum.Read:
                    Console.WriteLine("Reading physical drive to image file");

                    GenericPresenter.PresentPaths(arguments);

                    var readCommand = new ReadCommand(commandHelper, physicalDrives, arguments.SourcePath, arguments.DestinationPath,
                        arguments.Size);
                    readCommand.DataProcessed += (_, args) => { GenericPresenter.Present(args); };
                    await readCommand.Execute();
                    var readResult = await readCommand.Execute();
                    Console.WriteLine(readResult.IsSuccess ? "Done" : $"ERROR: Read failed, {readResult.Error}");
                    break;
                case Arguments.CommandEnum.Convert:
                    Console.WriteLine("Converting source image to destination image file");

                    GenericPresenter.PresentPaths(arguments);

                    var convertCommand = new ConvertCommand(commandHelper, physicalDrives, arguments.SourcePath, arguments.DestinationPath,
                        arguments.Size);
                    convertCommand.DataProcessed += (_, args) => { GenericPresenter.Present(args); };
                    var convertResult = await convertCommand.Execute();
                    Console.WriteLine(convertResult.IsSuccess ? "Done" : $"ERROR: Convert failed, {convertResult.Error}");
                    break;
                case Arguments.CommandEnum.Write:
                    Console.WriteLine("Writing source image file to physical drive");

                    GenericPresenter.PresentPaths(arguments);

                    var writeCommand = new WriteCommand(commandHelper, physicalDrives, arguments.SourcePath, arguments.DestinationPath,
                        arguments.Size);
                    writeCommand.DataProcessed += (_, args) => { GenericPresenter.Present(args); };
                    var writeResult = await writeCommand.Execute();
                    Console.WriteLine(writeResult.IsSuccess ? "Done" : $"ERROR: Write failed, {writeResult.Error}");
                    break;
                case Arguments.CommandEnum.Verify:
                    Console.WriteLine("Verifying source image to destination");

                    GenericPresenter.PresentPaths(arguments);

                    var verifyCommand = new VerifyCommand(commandHelper, physicalDrives, arguments.SourcePath, arguments.DestinationPath,
                        arguments.Size);
                    verifyCommand.DataProcessed += (_, args) => { GenericPresenter.Present(args); };
                    var verifyResult = await verifyCommand.Execute();
                    Console.WriteLine(verifyResult.IsSuccess ? "Done" : $"ERROR: Verify failed, {verifyResult.Error}");
                    break;
                case Arguments.CommandEnum.Blank:
                    Console.WriteLine("Creating blank image");
                    Console.WriteLine($"Path: {arguments.SourcePath}");
                    var blankCommand = new BlankCommand(commandHelper, arguments.SourcePath, arguments.Size);
                    var blankResult = await blankCommand.Execute();
                    Console.WriteLine(blankResult.IsSuccess ? "Done" : $"ERROR: Blank failed, {blankResult.Error}");
                    break;
                case Arguments.CommandEnum.Optimize:
                    Console.WriteLine("Optimizing image file");
                    Console.WriteLine($"Path: {arguments.SourcePath}");
                    var optimizeCommand = new OptimizeCommand(commandHelper, arguments.SourcePath);
                    var optimizeResult = await optimizeCommand.Execute();
                    Console.WriteLine(optimizeResult.IsSuccess ? "Done" : $"ERROR: Optimize failed, {optimizeResult.Error}");
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
    }
}