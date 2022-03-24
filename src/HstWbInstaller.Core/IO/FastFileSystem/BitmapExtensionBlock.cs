namespace HstWbInstaller.Core.IO.FastFileSystem
{
    using System.Collections.Generic;

    public class BitmapExtensionBlock
    {
        public uint Offset { get; set; }
        public byte[] BlockBytes { get; set; }
        public IEnumerable<BitmapBlock> BitmapBlocks { get; set; }
        public uint NextBitmapExtensionBlockPointer { get; set; }
    }
}