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
        [Fact(Skip = "Manual test")]
        public async Task Format()
        {
            var rigidDiskBlock = await RigidDiskBlock
                .Create(300.MB())
                .AddFileSystem("DOS3", await System.IO.File.ReadAllBytesAsync(@"d:\Temp\4gb\pc\ffs\FFS.40.1"))
                .AddPartition("DH0", bootable: true)
                .WriteToFile(@"d:\temp\partitioned_with_hstwb2.hdf");

            await using var stream = System.IO.File.OpenWrite(@"d:\temp\partitioned_with_hstwb2.hdf");
            await FastFileSystemFormatter.FormatPartition(stream, rigidDiskBlock.PartitionBlocks.First(), "WorkbenchHstWB");
        }
    }
}