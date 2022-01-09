namespace HstWbInstaller.Imager.ConsoleApp.PhysicalDrives
{
    using System.IO;

    public class WindowsPhysicalDrive : GenericPhysicalDrive
    {
        public WindowsPhysicalDrive(string path, string type, string model, ulong size) : base(
            path, type, model, size)
        {
        }

        public override Stream Open()
        {
            return new WindowsPhysicalDriveStream(Path);
        }
    }
}