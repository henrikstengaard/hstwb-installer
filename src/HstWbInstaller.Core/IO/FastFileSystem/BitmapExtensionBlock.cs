namespace HstWbInstaller.Core.IO.FastFileSystem
{
    using System.Collections.Generic;

    public class BitmapExtensionBlock
    {
//         struct bBitmapExtBlock {
// 000	int32_t	bmPages[127];
// 1fc	int32_t	nextBlock;
//         };        

        public int[] bmPages;

        public uint Offset { get; set; }
        public byte[] BlockBytes { get; set; }
        public IEnumerable<uint> BitmapBlockOffsets { get; set; }
        public uint NextBitmapExtensionBlockPointer { get; set; }
        public IEnumerable<BitmapBlock> BitmapBlocks { get; set; }

        public BitmapExtensionBlock()
        {
            bmPages = new int[127];
        }
    }
}