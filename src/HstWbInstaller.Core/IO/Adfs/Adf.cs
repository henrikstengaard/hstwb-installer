namespace HstWbInstaller.Core.IO.Adfs
{
    using System.IO;
    using System.Threading.Tasks;
    using Extensions;

    public static class Adf
    {
        public static byte[] CreateEmpty()
        {
            return new byte[901120];
        }

        public static async Task<byte[]> CreateBlank(string diskName)
        {
            var adfStream = new MemoryStream(CreateEmpty());

            // write id
            adfStream.Seek(0, SeekOrigin.Begin);
            var idBytes = new byte[] { 0x44, 0x4f, 0x53, 0x1 };
            await adfStream.WriteBytes(idBytes);
            
            // write root block
            var rootBlockBytes = await RootBlockWriter.BuildBlock(new RootBlock
            {
                DiskName = diskName
            });
            var rootBlockOffset = 880 * 512;
            adfStream.Seek(rootBlockOffset, SeekOrigin.Begin);
            await adfStream.WriteBytes(rootBlockBytes);
            
            // write bitmap block
            var bitmapBlockBytes = await BitmapBlockWriter.BuildBlock(new BitmapBlock());
            var bitmapBlockOffset = 881 * 512;
            adfStream.Seek(bitmapBlockOffset, SeekOrigin.Begin);
            await adfStream.WriteBytes(bitmapBlockBytes);

            return adfStream.ToArray();
        }
    }
}