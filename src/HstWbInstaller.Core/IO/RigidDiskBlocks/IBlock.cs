namespace HstWbInstaller.Core.IO.RigidDiskBlocks
{
    public interface IBlock
    {
        byte[] BlockBytes { get; set; }
        int Checksum { get; set; }
    }
}