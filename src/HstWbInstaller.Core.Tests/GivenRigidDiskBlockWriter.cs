namespace HstWbInstaller.Core.Tests
{
    using System.IO;
    using System.Threading.Tasks;
    using Extensions;
    using IO.RigidDiskBlocks;
    using Xunit;

    public class GivenRigidDiskBlockWriter : RigidDiskBlockTestBase
    {
        [Fact()]
        public async Task WhenCreateAndWriteRigidDiskBlockThenRigidDiskBlockIsEqual()
        {
            var path = "amiga.hdf";
            
            var rigidDiskBlock = await RigidDiskBlock
                .Create(10.MB().ToUniversalSize())
                .AddFileSystem("PDS3", await File.ReadAllBytesAsync(@"TestData\pfs3aio"))
                .AddPartition("DH0", 3.MB(), bootable: true)
                .AddPartition("DH1")
                .WriteToFile("amiga.hdf");

            await using var stream = File.OpenRead(path);
            var actualRigidDiskBlock = await RigidDiskBlockReader.Read(stream);

            var rigidDiskBlockJson = System.Text.Json.JsonSerializer.Serialize(rigidDiskBlock);
            var actualRigidDiskBlockJson = System.Text.Json.JsonSerializer.Serialize(actualRigidDiskBlock);
            Assert.Equal(rigidDiskBlockJson,actualRigidDiskBlockJson);
        }
    }
}