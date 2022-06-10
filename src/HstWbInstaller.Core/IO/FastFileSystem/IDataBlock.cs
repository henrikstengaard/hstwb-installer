namespace HstWbInstaller.Core.IO.FastFileSystem
{
    public interface IDataBlock
    {
        byte[] BlockBytes { get; set; }
        byte[] Data { get; set; }
    }
}