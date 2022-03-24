namespace HstWbInstaller.Core.Tests
{
    using System.IO;
    using System.Linq;
    using System.Threading.Tasks;
    using Extensions;
    using IO.FastFileSystem;
    using IO.RigidDiskBlocks;
    using Xunit;

    public class ManualFastFileSystemTests
    {
        [Fact(Skip = "Manual")]
        public async Task Format()
        {
            var rigidDiskBlock = await RigidDiskBlock
                .Create(300.MB())
                .AddFileSystem("DOS3", await File.ReadAllBytesAsync("FastFileSystem"))
                .AddPartition("DH0", bootable: true)
                .WriteToFile("hstwb.hdf");

            await using var stream = File.OpenWrite("hstwb.hdf");
            await FastFileSystemHelper.FormatPartition(stream, rigidDiskBlock.PartitionBlocks.First(), "WorkbenchHstWB");
        }
    }
}