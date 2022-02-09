namespace HstWbInstaller.Core.Tests
{
    using System.IO;
    using System.Linq;
    using System.Threading.Tasks;
    using IO.RigidDiskBlocks;
    using Xunit;

    public class GivenRigidDiskBlockReader
    {
        [Fact]
        public async Task WhenAmigaHardFileThenRigidDiskBlockIsValid()
        {
            // arrange hard file
            var hardFile = new MemoryStream(await File.ReadAllBytesAsync(Path.Combine("TestData", "rigid-disk-block.img")));

            // act read rigid disk block from hard file
            var rigidDiskBlock = await RigidDiskBlockReader.Read(hardFile);

            // assert rigid disk block
            Assert.NotNull(rigidDiskBlock);
            Assert.Equal("UAE", rigidDiskBlock.DiskVendor);
            Assert.Equal("HstWB 4GB", rigidDiskBlock.DiskProduct);
            Assert.Equal("0.4", rigidDiskBlock.DiskRevision);

            // assert number of partitions
            Assert.NotEmpty(rigidDiskBlock.PartitionBlocks);
            var partitionBlocks = rigidDiskBlock.PartitionBlocks.ToList();
            Assert.Equal(2, partitionBlocks.Count);

            // assert partition 1
            var partition1 = partitionBlocks[0];
            Assert.Equal("DH0", partition1.DriveName);

            // assert partition 2
            var partition2 = partitionBlocks[1];
            Assert.Equal("DH1", partition2.DriveName);
        }
    }
}