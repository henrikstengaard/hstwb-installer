namespace HstWbInstaller.Core.IO.RigidDiskBlocks
{
    using System;

    public class LoadSegBlock
    {
        public uint Size { get; set; }
        public int Checksum { get; set; }
        public uint HostId { get; set; }
        public int NextLoadSegBlock { get; set; }
        public byte[] Data { get; set; }

        public LoadSegBlock()
        {
            HostId = 7;
            NextLoadSegBlock = -1;
            Data = Array.Empty<byte>();
        }
    }
}