namespace HstWbInstaller.Imager.Core
{
    using System;
    using Microsoft.Extensions.Logging;
    using PhysicalDrives;

    public class PhysicalDriveManagerFactory
    {
        private readonly ILoggerFactory loggerFactory;

        public PhysicalDriveManagerFactory(ILoggerFactory loggerFactory)
        {
            this.loggerFactory = loggerFactory;
        }

        public IPhysicalDriveManager Create()
        {
            if (OperatingSystem.IsWindows())
            {
                return new WindowsPhysicalDriveManager(this.loggerFactory.CreateLogger<WindowsPhysicalDriveManager>());
            }

            if (OperatingSystem.IsMacOs())
            {
                return new MacOsPhysicalDriveManager(this.loggerFactory.CreateLogger<MacOsPhysicalDriveManager>());
            }

            if (OperatingSystem.IsLinux())
            {
                return new LinuxPhysicalDriveManager(this.loggerFactory.CreateLogger<LinuxPhysicalDriveManager>());
            }
            
            throw new NotSupportedException("Unsupported operating system");
        }        
    }
}