namespace HstWbInstaller.Core.IO.RigidDiskBlocks
{
    using System;

    public class BadBlock : BlockBase
    {
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