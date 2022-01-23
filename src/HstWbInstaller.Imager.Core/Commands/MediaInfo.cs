namespace HstWbInstaller.Imager.Core.Commands
{
    using HstWbInstaller.Core.IO.RigidDiskBlocks;
    using Models;

    public class MediaInfo
    {
        public string Path { get; set; }
        public string Model { get; set; }
        public bool IsPhysicalDrive;
        public Media.MediaType Type;        
        public long DiskSize { get; set; }
        public RigidDiskBlock RigidDiskBlock { get; set; }
    }
}