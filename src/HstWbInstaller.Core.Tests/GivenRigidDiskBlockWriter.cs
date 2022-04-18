namespace HstWbInstaller.Core.Tests
{
    using System.IO;
    using System.Linq;
    using System.Threading.Tasks;
    using Extensions;
    using IO.RigidDiskBlocks;
    using Xunit;

    public class GivenRigidDiskBlockWriter : RigidDiskBlockTestBase
    {
        [Fact()]
        public async Task WhenCreateAndWriteRigidDiskBlockThenRigidDiskBlockIsEqual()
        {
            var path = @"d:\Temp\pfs3_format_amiga\pfs3_format_amiga.hdf";

            var rigidDiskBlock = RigidDiskBlock
                .Create(300.MB().ToUniversalSize())
                .AddFileSystem("PFS3", await File.ReadAllBytesAsync(@"TestData\pfs3aio"))
                .AddPartition("DH0", bootable: true);
                //.WriteToFile(path);
                var partitionBlock = rigidDiskBlock.PartitionBlocks.First();
            await using var stream = File.OpenRead(path);
            var actualRigidDiskBlock = await RigidDiskBlockReader.Read(stream);

            var rigidDiskBlockJson = System.Text.Json.JsonSerializer.Serialize(rigidDiskBlock);
            var actualRigidDiskBlockJson = System.Text.Json.JsonSerializer.Serialize(actualRigidDiskBlock);
            Assert.Equal(rigidDiskBlockJson,actualRigidDiskBlockJson);
        }
    }
}