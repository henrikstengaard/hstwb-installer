namespace HstWbInstaller.Core.IO.RigidDiskBlocks
{
    [System.Flags]
    public enum PartitionFlagsEnum
    {
        Bootable = 1,
        NoMount = 2,
        Raid = 4,
        Lvm = 8        
    }
}