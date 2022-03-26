namespace HstWbInstaller.Core.IO.FastFileSystem
{
    /// <summary>
    /// A bitmap block contain information about free and allocated blocks.
    /// One bit is used per block. If the bit is set, the block is free, a cleared bit means an allocated block.
    /// </summary>
    public class BitmapBlock
    {
        public uint Offset { get; set; }
        public byte[] BlockBytes { get; set; }
        public int Checksum { get; set; }
        
        public bool[] BlocksFreeMap { get; set; }
    }
}