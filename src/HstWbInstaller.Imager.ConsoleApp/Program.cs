﻿namespace HstWbInstaller.Imager.ConsoleApp
{
    using System;
    using System.Collections.Generic;
    using System.CommandLine;
    using System.Diagnostics;
    using System.IO;
    using System.Linq;
    using System.Threading;
    using System.Threading.Tasks;
    using Core;
    using Core.Commands;
    using Core.Extensions;
    using Core.Helpers;
    using Core.PhysicalDrives;
    using Microsoft.Extensions.DependencyInjection;
    using Microsoft.Extensions.Logging;
    using Microsoft.Extensions.Logging.Abstractions;
    using Presenters;
    using Serilog;
    using OperatingSystem = HstWbInstaller.Core.OperatingSystem;

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
            // var workerFileName = $"HstWbInstaller.Imager.GuiApp.exe";
            // var currentProcessId = Process.GetCurrentProcess().Id;
            // var processes = Process.GetProcesses();
            //
            // foreach (var process in processes)
            // {
            //     try
            //     {
            //         if (process.Id == currentProcessId ||
            //             process.ProcessName.IndexOf("HstWbInstaller.Imager.GuiApp", StringComparison.OrdinalIgnoreCase) < 0 ||
            //             process.MainModule == null ||
            //             process.MainModule.FileName == null ||
            //             process.MainModule.FileName.IndexOf(workerFileName, StringComparison.OrdinalIgnoreCase) < 0)
            //         {
            //             continue;
            //         }
            //     }
            //     catch (Exception)
            //     {
            //         continue;
            //     }
            //
            //     var kill = process.MainModule.FileName;
            //     //process.Kill();
            // }            
            
            //var process = ElevateHelper.StartElevatedProcess("HstWB Installer", "cmd.exe");
            // await process.WaitForExitAsync();

            //var process = ElevateHelper.StartElevatedProcess("HstWB Installer", "cmd.exe");
            // await process.WaitForExitAsync();
            //
            //await "/usr/bin/osascript".RunProcessAsync("-e 'do shell script \"/bin/bash\" with prompt \"{prompt}\" with administrator privileges'");
            //return 0;
            
            var mbrTest = new MbrTest();
            mbrTest.Create();
            mbrTest.Read();

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

            var physicalDriveManager = new PhysicalDriveManagerFactory(new NullLoggerFactory()).Create();

            return (await physicalDriveManager.GetPhysicalDrives()).ToList();
        }


        static async Task Run(Arguments arguments)
        {
            Log.Logger = new LoggerConfiguration()
                .Enrich.FromLogContext()
                .WriteTo.Console()
                .CreateLogger();
            
            var serviceProvider = new ServiceCollection()
                .AddLogging(loggingBuilder => loggingBuilder.AddSerilog(dispose: true))
                .BuildServiceProvider();

            var loggerFactory = serviceProvider.GetService<ILoggerFactory>();

            var isAdministrator = OperatingSystem.IsAdministrator();

            if (!isAdministrator)
            {
                Console.WriteLine("Requires administrator rights!");
            }

            var commandHelper = new CommandHelper();
            var physicalDrives = (await GetPhysicalDrives(arguments)).ToList();
            var cancellationTokenSource = new CancellationTokenSource();

            switch (arguments.Command)
            {
                case Arguments.CommandEnum.List:
                    var listCommand = new ListCommand(loggerFactory.CreateLogger<ListCommand>(), commandHelper, physicalDrives);
                    listCommand.ListRead += (_, args) =>
                    {
                        //
                        // await Task.Run(() =>
                        // {
                        //     Console.WriteLine(JsonSerializer.Serialize(physicalDrivesList, JsonSerializerOptions));
                        // });
                        InfoPresenter.PresentInfo(args.MediaInfos);
                    };
                    var listResult = await listCommand.Execute(cancellationTokenSource.Token);
                    Console.WriteLine(listResult.IsSuccess ? "Done" : $"ERROR: Read failed, {listResult.Error}");
                    break;
                case Arguments.CommandEnum.Info:
                    var infoCommand = new InfoCommand(loggerFactory.CreateLogger<InfoCommand>(), commandHelper, physicalDrives, arguments.SourcePath);
                    infoCommand.DiskInfoRead += (_, args) => { InfoPresenter.PresentInfo(args.MediaInfo); };
                    var infoResult = await infoCommand.Execute(cancellationTokenSource.Token);
                    Console.WriteLine(infoResult.IsSuccess ? "Done" : $"ERROR: Read failed, {infoResult.Error}");
                    break;
                case Arguments.CommandEnum.Read:
                    Console.WriteLine("Reading physical drive to image file");

                    GenericPresenter.PresentPaths(arguments);

                    var readCommand = new ReadCommand(loggerFactory.CreateLogger<ReadCommand>(), commandHelper, physicalDrives, arguments.SourcePath,
                        arguments.DestinationPath,
                        arguments.Size);
                    readCommand.DataProcessed += (_, args) => { GenericPresenter.Present(args); };
                    var readResult = await readCommand.Execute(cancellationTokenSource.Token);
                    Console.WriteLine(readResult.IsSuccess ? "Done" : $"ERROR: Read failed, {readResult.Error}");
                    break;
                case Arguments.CommandEnum.Convert:
                    Console.WriteLine("Converting source image to destination image file");

                    GenericPresenter.PresentPaths(arguments);

                    var convertCommand = new ConvertCommand(loggerFactory.CreateLogger<ConvertCommand>(), commandHelper, arguments.SourcePath,
                        arguments.DestinationPath,
                        arguments.Size);
                    convertCommand.DataProcessed += (_, args) => { GenericPresenter.Present(args); };
                    var convertResult = await convertCommand.Execute(cancellationTokenSource.Token);
                    Console.WriteLine(
                        convertResult.IsSuccess ? "Done" : $"ERROR: Convert failed, {convertResult.Error}");
                    break;
                case Arguments.CommandEnum.Write:
                    Console.WriteLine("Writing source image file to physical drive");

                    GenericPresenter.PresentPaths(arguments);

                    var writeCommand = new WriteCommand(loggerFactory.CreateLogger<WriteCommand>(), commandHelper, physicalDrives, arguments.SourcePath,
                        arguments.DestinationPath,
                        arguments.Size);
                    writeCommand.DataProcessed += (_, args) => { GenericPresenter.Present(args); };
                    var writeResult = await writeCommand.Execute(cancellationTokenSource.Token);
                    Console.WriteLine(writeResult.IsSuccess ? "Done" : $"ERROR: Write failed, {writeResult.Error}");
                    break;
                case Arguments.CommandEnum.Verify:
                    Console.WriteLine("Verifying source image to destination");

                    GenericPresenter.PresentPaths(arguments);

                    var verifyCommand = new VerifyCommand(loggerFactory.CreateLogger<VerifyCommand>(), commandHelper, physicalDrives, arguments.SourcePath,
                        arguments.DestinationPath,
                        arguments.Size);
                    verifyCommand.DataProcessed += (_, args) => { GenericPresenter.Present(args); };
                    var verifyResult = await verifyCommand.Execute(cancellationTokenSource.Token);
                    Console.WriteLine(verifyResult.IsSuccess ? "Done" : $"ERROR: Verify failed, {verifyResult.Error}");
                    break;
                case Arguments.CommandEnum.Blank:
                    Console.WriteLine("Creating blank image");
                    Console.WriteLine($"Path: {arguments.SourcePath}");
                    var blankCommand = new BlankCommand(loggerFactory.CreateLogger<BlankCommand>(), commandHelper, arguments.SourcePath, arguments.Size);
                    var blankResult = await blankCommand.Execute(cancellationTokenSource.Token);
                    Console.WriteLine(blankResult.IsSuccess ? "Done" : $"ERROR: Blank failed, {blankResult.Error}");
                    break;
                case Arguments.CommandEnum.Optimize:
                    Console.WriteLine("Optimizing image file");
                    Console.WriteLine($"Path: {arguments.SourcePath}");
                    var optimizeCommand = new OptimizeCommand(loggerFactory.CreateLogger<OptimizeCommand>(), commandHelper, arguments.SourcePath);
                    var optimizeResult = await optimizeCommand.Execute(cancellationTokenSource.Token);
                    Console.WriteLine(optimizeResult.IsSuccess
                        ? "Done"
                        : $"ERROR: Optimize failed, {optimizeResult.Error}");
                    break;
            }
        }
    }
}