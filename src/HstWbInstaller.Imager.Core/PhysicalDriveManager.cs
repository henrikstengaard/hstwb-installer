namespace HstWbInstaller.Imager.Core
{
    using System;
    using PhysicalDrives;

    public static class PhysicalDriveManager
    {
        public static IPhysicalDriveManager Create(bool fake = false)
        {
            if (OperatingSystem.IsWindows())
            {
                return new WindowsPhysicalDriveManager(fake);
            }

            if (OperatingSystem.IsLinux())
            {
                return new LinuxPhysicalDriveManager(fake);
            }
            
            throw new NotImplementedException("Unsupported operating system");
        }        
    }
}