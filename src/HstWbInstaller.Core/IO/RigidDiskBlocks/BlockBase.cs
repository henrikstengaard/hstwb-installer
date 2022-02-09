namespace HstWbInstaller.Core.IO.RigidDiskBlocks
{
    public abstract class BlockBase : IBlock
    {
        public byte[] BlockBytes { get; set; }
        public int Checksum { get; set; }
    }
}