namespace HstWbInstaller.Imager.Core.PhysicalDrives
{
    using System.IO;
    using HstWbInstaller.Core.IO.RigidDiskBlocks;

    public class GenericPhysicalDrive : IPhysicalDrive
    {
        public string Path { get; }
        public string Type { get; }
        public string Model { get; }
        public long Size { get; }
        public RigidDiskBlock RigidDiskBlock { get; set; }

        public GenericPhysicalDrive(string path, string type, string model, long size)
        {
            Path = path;
            Type = type;
            Model = model;
            Size = size;
        }

        public virtual Stream Open()
        {
            return File.Open(Path, FileMode.Open, FileAccess.ReadWrite);
        }
    }
}