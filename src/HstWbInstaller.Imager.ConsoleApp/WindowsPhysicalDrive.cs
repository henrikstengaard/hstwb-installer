namespace HstWbInstaller.Imager.ConsoleApp
{
    using System.IO;
    using Core;

    public class WindowsPhysicalDrive : IPhysicalDrive
    {
        public string Path { get; }
        public string Type { get; }
        public string Model { get; }
        public ulong Size { get; }

        public WindowsPhysicalDrive(string path, string type, string model, ulong size)
        {
            Path = path;
            Type = type;
            Model = model;
            Size = size;
        }

        public Stream Open()
        {
            return new WindowsPhysicalDriveStream(Path);
        }
    }

    public class GenericPhysicalDrive : IPhysicalDrive
    {
        public string Path { get; }
        public string Type { get; }
        public string Model { get; }
        public ulong Size { get; }

        public GenericPhysicalDrive(string path, string type, string model, ulong size)
        {
            Path = path;
            Type = type;
            Model = model;
            Size = size;
        }

        public Stream Open()
        {
            return File.Open(Path, FileMode.Open, FileAccess.ReadWrite);
        }
    }
}