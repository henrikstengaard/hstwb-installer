namespace HstWbInstaller.Imager.Core
{
    using System.IO;

    public interface IPhysicalDrive
    {
        string Path { get; }
        string Type { get; }
        string Model { get; }
        ulong Size { get; }
        
        Stream Open();
    }
}