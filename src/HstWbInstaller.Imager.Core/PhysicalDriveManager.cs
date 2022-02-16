namespace HstWbInstaller.Imager.Core
{
    using System;
    using PhysicalDrives;

    public static class PhysicalDriveManager
    {
        public static IPhysicalDriveManager Create()
        {
            if (OperatingSystem.IsWindows())
            {
                return new WindowsPhysicalDriveManager();
            }

            if (OperatingSystem.IsMacOs())
            {
                return new MacOsPhysicalDriveManager();
            }

            if (OperatingSystem.IsLinux())
            {
                return new LinuxPhysicalDriveManager();
            }
            
            throw new NotImplementedException("Unsupported operating system");
        }        
    }
}