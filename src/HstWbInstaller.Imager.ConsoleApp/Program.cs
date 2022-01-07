using System;

namespace HstWbInstaller.Imager.ConsoleApp
{
    using System.IO;
    using System.Linq;
    using System.Text.Json;
    using System.Threading.Tasks;
    using HstWbInstaller.Core.IO.RigidDiskBlocks;

    class Program
    {
        static async Task Main(string[] args)
        {
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
            
            var physicalDriveManager = new WindowsPhysicalDriveManager();
            var physicalDrives = physicalDriveManager.GetPhysicalDrives().ToList();
            Console.WriteLine(JsonSerializer.Serialize(physicalDrives));

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
                    Console.WriteLine($"Failed to read first {buffer.Length} bytes from physical drive '{physicalDrive.Path}': {e}");
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

            // foreach (var drive in PhysicalDrive.Drives)
            // {
            //     // linux
            //     // lsblk -o TYPE,NAME,VENDOR,MODEL,SERIAL,PATH,SIZE --json
            //     
            //     // requires admin mode to read and write disks
            //     var m = $"Drive {drive.DriveNumber}, Size {drive.Size}";
            //     
            //     Console.WriteLine(m);
            //     
            //     
            // }
        }
    }
}