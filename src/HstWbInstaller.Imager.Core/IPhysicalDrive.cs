namespace HstWbInstaller.Imager.Core
{
    using System.IO;
    using HstWbInstaller.Core.IO.RigidDiskBlocks;

    public interface IPhysicalDrive
    {
        string Path { get; }
        string Type { get; }
        string Model { get; }
        ulong Size { get; }
        RigidDiskBlock RigidDiskBlock { get; set; }

        Stream Open();
    }
}