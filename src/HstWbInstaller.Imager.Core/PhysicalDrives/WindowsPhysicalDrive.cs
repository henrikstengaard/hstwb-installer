namespace HstWbInstaller.Imager.Core.PhysicalDrives
{
    using System.IO;

    public class WindowsPhysicalDrive : GenericPhysicalDrive
    {
        public WindowsPhysicalDrive(string path, string type, string model, long size) : base(
            path, type, model, size)
        {
        }

        public override Stream Open()
        {
            return new WindowsPhysicalDriveStream(Path);
        }
    }
}