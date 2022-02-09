namespace HstWbInstaller.Core.Extensions
{
    using System;
    using System.IO;
    using System.Linq;
    using System.Threading.Tasks;
    using IO.RigidDiskBlocks;
    using IO.Versions;

    public static class RigidDiskBlockExtensions
    {
        public static RigidDiskBlock CreateRigidDiskBlock(this long size) => RigidDiskBlock.Create(size);

        public static RigidDiskBlock AddFileSystem(this RigidDiskBlock rigidDiskBlock,
            string dosType, byte[] fileSystemBytes)
        {
            return rigidDiskBlock.AddFileSystem(FormatHelper.FormatDosType(dosType), fileSystemBytes);
        }

        public static RigidDiskBlock AddFileSystem(this RigidDiskBlock rigidDiskBlock,
            byte[] dosType, byte[] fileSystemBytes)
        {
            var version = VersionReader.Read(fileSystemBytes);
            var fileVersion = VersionReader.Parse(version);

            var fileSystemHeaderBlock = BlockHelper.CreateFileSystemHeaderBlock(dosType, fileVersion.Version,
                fileVersion.Revision,
                fileSystemBytes);

            rigidDiskBlock.FileSystemHeaderBlocks = rigidDiskBlock.FileSystemHeaderBlocks.Concat(new[]
                    { fileSystemHeaderBlock });

            return rigidDiskBlock;
        }

        public static RigidDiskBlock AddPartition(this RigidDiskBlock rigidDiskBlock,
            string driveName, long size = 0, bool bootable = false)
        {
            var firstFileSystemHeaderBlock = rigidDiskBlock.FileSystemHeaderBlocks.FirstOrDefault();

            if (firstFileSystemHeaderBlock == null)
            {
                throw new Exception("No file system header blocks");
            }

            return AddPartition(rigidDiskBlock, firstFileSystemHeaderBlock.DosType, driveName, size, bootable);
        }

        public static RigidDiskBlock AddPartition(this RigidDiskBlock rigidDiskBlock, byte[] dosType, string driveName, long size = 0,
            bool bootable = false)
        {
            var partitionBlock = PartitionBlock.Create(rigidDiskBlock, dosType, driveName, size, bootable);
            rigidDiskBlock.PartitionBlocks = rigidDiskBlock.PartitionBlocks.Concat(new[] { partitionBlock });

            return rigidDiskBlock;
        }

        public static async Task<RigidDiskBlock> WriteToFile(this RigidDiskBlock rigidDiskBlock, string path)
        {
            // create file
            await using var stream = File.Open(path, FileMode.Create);

            // set length to preallocate
            stream.SetLength(rigidDiskBlock.DiskSize);

            await WriteToStream(rigidDiskBlock, stream);

            return rigidDiskBlock;
        }

        public static async Task<RigidDiskBlock> WriteToStream(this RigidDiskBlock rigidDiskBlock, Stream stream)
        {
            await RigidDiskBlockWriter.WriteBlock(rigidDiskBlock, stream);

            return rigidDiskBlock;
        }
    }
}