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
        public bool Writable { get; set; }
        public RigidDiskBlock RigidDiskBlock { get; set; }

        public GenericPhysicalDrive(string path, string type, string model, long size, bool writable = false)
        {
            Path = path;
            Type = type;
            Model = model;
            Size = size;
            Writable = writable;
        }

        public virtual Stream Open()
        {
            return File.Open(Path, FileMode.Open, FileAccess.ReadWrite);
        }

        public void SetWritable(bool writable)
        {
            Writable = writable;
        }
    }
}