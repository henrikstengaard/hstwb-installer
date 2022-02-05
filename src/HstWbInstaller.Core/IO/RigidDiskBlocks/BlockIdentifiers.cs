namespace HstWbInstaller.Core.IO.RigidDiskBlocks
{
    public static class BlockIdentifiers
    {
        public const string RigidDiskBlock = "RDSK";
        public const string PartitionBlock = "PART";
        public const string FileSystemHeaderBlock = "FSHD";
        public const string LoadSegBlock = "LSEG";
        public const string BadBlock = "BADB";

        public const uint EndOfBlock = 4294967295;
    }
}