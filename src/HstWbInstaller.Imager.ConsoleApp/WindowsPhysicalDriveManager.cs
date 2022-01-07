namespace HstWbInstaller.Imager.ConsoleApp
{
    using System;
    using System.Collections.Generic;
    using System.Diagnostics;
    using System.Management;
    using System.Linq;
    using System.Text.Json;
    using Core;

    public class WindowsPhysicalDriveManager : IPhysicalDriveManager
    {
        public IEnumerable<IPhysicalDrive> GetPhysicalDrives()
        {
#pragma warning disable CA1416
            var searcher = new ManagementObjectSearcher("SELECT * FROM Win32_DiskDrive");
#pragma warning restore CA1416

#pragma warning disable CA1416
            foreach (var o in searcher.Get())
#pragma warning restore CA1416
            {
                var info = (ManagementObject)o;
#pragma warning disable CA1416
                yield return new WindowsPhysicalDrive(info["DeviceID"].ToString(), info["MediaType"].ToString(),
                    info["Model"].ToString(), (UInt64)info["Size"]);
#pragma warning restore CA1416
            }
        }
    }

    public class LinuxPhysicalDriveManager : IPhysicalDriveManager
    {
        public IEnumerable<IPhysicalDrive> GetPhysicalDrives()
        {
            var process = Process.Start(new ProcessStartInfo("lsblk", "-ba -o TYPE,NAME,VENDOR,MODEL,SERIAL,PATH,SIZE --json")
            {
                RedirectStandardOutput = true,
                CreateNoWindow = true,
                UseShellExecute = false
            });
            var output = process.StandardOutput.ReadToEnd();

            System.IO.File.WriteAllText("lsblk.txt", output);
            var lsBlk = JsonSerializer.Deserialize<LsBlk>(output);

            return lsBlk.BlockDevices.Select(x => new GenericPhysicalDrive(x.Path, x.Type, x.Model, x.Size));
        }
    }

    public class LsBlk
    {
        [JsonPropertyName("blockdevices")]
        public IEnumerable<BlockDevice> BlockDevices { get;set; }
    }

    public class BlockDevice
    {
        [JsonPropertyName("path")]
        public string Path { get;set; }

        [JsonPropertyName("type")]
        public string Type { get;set; }

        [JsonPropertyName("model")]
        public string Model { get;set; }

        [JsonPropertyName("size")]
        public ulong Size { get;set; }
    }


}