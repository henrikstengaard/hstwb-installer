namespace HstWbInstaller.Imager.ConsoleApp
{
    using System;
    using System.Collections.Generic;
    using System.Management;
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
}