namespace HstWbInstaller.Core.IO.FastFileSystem
{
    public class DataBlock : IDataBlock
    {
        public byte[] BlockBytes { get; set; }
        public byte[] Data { get; set; }
    }
}