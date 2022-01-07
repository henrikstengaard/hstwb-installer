namespace HstWbInstaller.Imager.Core
{
    using System.Collections.Generic;

    public interface IPhysicalDriveManager
    {
        IEnumerable<IPhysicalDrive> GetPhysicalDrives();
    }
}