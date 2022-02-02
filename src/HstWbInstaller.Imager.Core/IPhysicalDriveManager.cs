namespace HstWbInstaller.Imager.Core
{
    using System.Collections.Generic;
    using System.Linq;
    using System.Threading.Tasks;

    public interface IPhysicalDriveManager
    {
        Task<IEnumerable<IPhysicalDrive>> GetPhysicalDrives();
    }
}