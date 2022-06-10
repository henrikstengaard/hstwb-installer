namespace HstWbInstaller.Core.IO.Pfs3
{
    using System.IO;
    using System.Threading.Tasks;
    using Blocks;
    using Extensions;

    public static class BootBlockWriter
    {
        public static async Task<byte[]> MakeBootBlock(BootBlock bootBlock)
        {
            var blockStream = bootBlock.BlockBytes == null || bootBlock.BlockBytes.Length == 0 ?
                new MemoryStream() : new MemoryStream(bootBlock.BlockBytes);
            
            await blockStream.WriteLittleEndianInt32(bootBlock.disktype);
            
            bootBlock.BlockBytes = blockStream.ToArray();
            return bootBlock.BlockBytes;            
        }
    }
}