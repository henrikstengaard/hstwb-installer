namespace HstWbInstaller.Core.IO.Adfs
{
    using System;
    using System.IO;
    using System.Threading.Tasks;
    using Extensions;
    using RigidDiskBlocks;

    public static class RootBlockWriter
    {
        public static async Task<byte[]> BuildBlock(RootBlock rootBlock)
        {
            var blockStream =
                new MemoryStream(
                    rootBlock.BlockBytes == null || rootBlock.BlockBytes.Length == 0
                        ? new byte[512]
                        : rootBlock.BlockBytes);
            
            await blockStream.WriteLittleEndianInt32(2); // type

            blockStream.Seek(12, SeekOrigin.Begin);
            await blockStream.WriteLittleEndianInt32(0x48); // ht_size
            
            blockStream.Seek(312, SeekOrigin.Begin);
            await blockStream.WriteLittleEndianInt32(-1); // bm_flag				
            await blockStream.WriteLittleEndianInt32(881); // bm_pages (sector with bitmap block)

            var now = DateTime.UtcNow;
            var amigaDate = new DateTime(1978, 1, 1, 0, 0, 0, DateTimeKind.Utc);
            var creatingDate = now - amigaDate;
            var creationDays = creatingDate.Days;
            var creationMinutes = creatingDate.Hours * 60 + creatingDate.Minutes;
            var creationTicks = Convert.ToInt32((double)50 / 60 * creatingDate.Seconds);
            
            blockStream.Seek(420, SeekOrigin.Begin);
            await blockStream.WriteLittleEndianInt32(creationDays); // last root alteration date : days since 1 jan 78
            await blockStream.WriteLittleEndianInt32(creationMinutes); // minutes past midnight
            await blockStream.WriteLittleEndianInt32(creationTicks); // ticks (1/50 sec) past last minute

            var diskName = rootBlock.DiskName.Length > 30
                ? rootBlock.DiskName.Substring(0, 30)
                : rootBlock.DiskName;

            await blockStream.WriteBytes(new[] { Convert.ToByte(diskName.Length) });
            await blockStream.WriteString(diskName, 30);

            blockStream.Seek(472, SeekOrigin.Begin);
            await blockStream.WriteLittleEndianInt32(0); // last disk alteration date : days since 1 jan 78
            await blockStream.WriteLittleEndianInt32(0); // minutes past midnight
            await blockStream.WriteLittleEndianInt32(0); // ticks (1/50 sec) past last minute

            await blockStream.WriteLittleEndianInt32(creationDays); // filesystem creation date
            await blockStream.WriteLittleEndianInt32(creationMinutes); // minutes past midnight
            await blockStream.WriteLittleEndianInt32(creationTicks); // ticks (1/50 sec) past last minute
            
            blockStream.Seek(504, SeekOrigin.Begin);
            await blockStream.WriteLittleEndianInt32(0); // FFS: first directory cache block, 0 otherwise
            await blockStream.WriteLittleEndianInt32(1); // block secondary type = ST_ROOT (value 1)
            
            // calculate and update checksum
            var blockBytes = blockStream.ToArray();
            rootBlock.Checksum = await BlockHelper.UpdateChecksum(blockBytes, 20);
            rootBlock.BlockBytes = blockBytes;

            return blockBytes;
        }
    }

    public class RootBlock
    {
        public byte[] BlockBytes { get; set; }
        public int Checksum { get; set; }
        public string DiskName { get; set; }
        public DateTime RootAlterationDate { get; set; }
        public DateTime DiskAlterationDate { get; set; }
        public DateTime FileSystemCreationDate { get; set; }
    }
    
    public static class BitmapBlockWriter
    {
        public static async Task<byte[]> BuildBlock(BitmapBlock bitmapBlock)
        {
            var blockStream =
                new MemoryStream(
                    bitmapBlock.BlockBytes == null || bitmapBlock.BlockBytes.Length == 0
                        ? new byte[512]
                        : bitmapBlock.BlockBytes);
            
            await blockStream.WriteLittleEndianInt32(0); // checksum

            // free sectors
            var freeSectorBytes = new byte[] { 0xff, 0xff, 0xff, 0xff };
            for (var i = 0; i < 27; i++)
            {
                await blockStream.WriteBytes(freeSectorBytes);
            }

            var rootBitmapBytes = new byte[] { 0xff, 0xff, 0x3f, 0xff };
            await blockStream.WriteBytes(rootBitmapBytes);
            
            // free sectors
            for (var i = 0; i < 27; i++)
            {
                await blockStream.WriteBytes(freeSectorBytes);
            }
            
            // unused
            for (var i = 0; i < 72; i++)
            {
                await blockStream.WriteLittleEndianInt32(0);
            }
            
            // calculate and update checksum
            var bitmapBytes = blockStream.ToArray();
            bitmapBlock.Checksum = await BlockHelper.UpdateChecksum(bitmapBytes, 0);
            bitmapBlock.BlockBytes = bitmapBytes;

            return bitmapBytes;            
        }
    }

    public class BitmapBlock
    {
        public byte[] BlockBytes { get; set; }
        public int Checksum { get; set; }
    }
}