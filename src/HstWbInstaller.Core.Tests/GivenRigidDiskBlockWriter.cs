namespace HstWbInstaller.Core.Tests
{
    using System.IO;
    using System.Threading.Tasks;
    using IO.RigidDiskBlocks;
    using Xunit;

    public class GivenRigidDiskBlockWriter : RigidDiskBlockTestBase
    {
        [Fact(Skip = "Used for manual testing")]
        public async Task WhenWrite()
        {
            await Create();
            
            await using var stream = File.Open("new.hdf", FileMode.Open);

            var rigidDiskBlock = await RigidDiskBlockReader.Read(stream);
        }

        public async Task Create()
        {
            var diskSize = 1024 * 1024 * 250;

            var rigidDiskBlock = CreateRigidDiskBlock(diskSize);

            var fileSystemHeaderBlock = await CreateFileSystemHeaderBlock();

            var partitionBlock = CreatePartitionBlock(rigidDiskBlock, 0, 1024 * 1024 * 100,
                fileSystemHeaderBlock.DosType, "DH0", bootable: true);

            rigidDiskBlock.LoCylinder = partitionBlock.LowCyl;
            rigidDiskBlock.HiCylinder = rigidDiskBlock.Cylinders - 1;
            
            rigidDiskBlock.PartitionBlocks = new[] { partitionBlock };
            rigidDiskBlock.FileSystemHeaderBlocks = new[] { fileSystemHeaderBlock };            
            
            await using var stream = File.Open("new.hdf", FileMode.Create);
            
            // create length
            stream.SetLength(diskSize);

            await RigidDiskBlockWriter.WriteBlock(rigidDiskBlock, stream);
        }
    }
}