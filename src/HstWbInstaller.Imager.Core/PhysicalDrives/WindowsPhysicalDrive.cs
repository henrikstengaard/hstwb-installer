namespace HstWbInstaller.Imager.Core.PhysicalDrives
{
    using System.Collections.Generic;
    using System.IO;
    using System.Linq;
    using Apis;

    public class WindowsPhysicalDrive : GenericPhysicalDrive
    {
        public readonly IEnumerable<string> DriveLetters;

        public WindowsPhysicalDrive(string path, string type, string model, long size, IEnumerable<string> driveLetters) : base(
            path, type, model, size)
        {
            this.DriveLetters = driveLetters;
        }

        public override Stream Open()
        {
            if (Writable)
            {
                foreach (var driveLetter in DriveLetters.ToList())
                {
                    string path = @"\\.\" + driveLetter + @"";
                    using var win32RawDisk = new Win32RawDisk(path, true);
                }
            }
            return new WindowsPhysicalDriveStream(Path, Size, Writable);
        }
    }
}