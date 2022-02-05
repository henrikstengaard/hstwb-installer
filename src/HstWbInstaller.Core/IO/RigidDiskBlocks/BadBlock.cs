namespace HstWbInstaller.Core.IO.RigidDiskBlocks
{
    using System;

    public class BadBlock
    {
        public uint Size { get; set; }
        public int Checksum { get; set; }
        public uint HostId { get; set; }
        public uint NextBadBlock { get; set; }
        public byte[] Data { get; set; }
        
        public BadBlock()
        {
            HostId = 7;
            NextBadBlock = BlockIdentifiers.EndOfBlock;
            Data = Array.Empty<byte>();
        }
    }
}