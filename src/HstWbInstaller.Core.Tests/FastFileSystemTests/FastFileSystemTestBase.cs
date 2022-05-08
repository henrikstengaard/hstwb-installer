namespace HstWbInstaller.Core.Tests.FastFileSystemTests
{
    using System;
    using System.IO;
    using System.Threading.Tasks;
    using Extensions;
    using IO;

    public abstract class FastFileSystemTestBase
    {
        protected readonly DateTime Date = new DateTime(2022, 2, 3, 14, 45, 33, DateTimeKind.Utc);
        
        protected async Task<byte[]> CreateExpectedRootBlockBytes()
        {
            var blockStream = new MemoryStream(new byte[512]);

            await blockStream.WriteLittleEndianInt32(2); // type

            blockStream.Seek(12, SeekOrigin.Begin);
            await blockStream.WriteLittleEndianInt32(0x48); // ht_size

            blockStream.Seek(312, SeekOrigin.Begin);
            await blockStream.WriteLittleEndianInt32(-1); // bm_flag				
            await blockStream.WriteLittleEndianInt32(881); // bm_pages (sector with bitmap block)

            blockStream.Seek(420, SeekOrigin.Begin);

            var amigaDate = new DateTime(1978, 1, 1, 0, 0, 0, DateTimeKind.Utc);
            var diffDate = Date - amigaDate;
            var days = diffDate.Days;
            var minutes = diffDate.Hours * 60 + diffDate.Minutes;
            var ticks = Convert.ToInt32(diffDate.Milliseconds);
            
            // last root alteration date
            await blockStream.WriteLittleEndianInt32(days); // days since 1 jan 78
            await blockStream.WriteLittleEndianInt32(minutes); // minutes past midnight
            await blockStream.WriteLittleEndianInt32(ticks); // ticks (1/50 sec) past last minute

            var diskName = "HstWB";
            await blockStream.WriteBytes(new[] { Convert.ToByte(diskName.Length) });
            await blockStream.WriteString(diskName, 30);       

            // last disk alteration date
            blockStream.Seek(472, SeekOrigin.Begin);
            await blockStream.WriteLittleEndianInt32(0); // days since 1 jan 78
            await blockStream.WriteLittleEndianInt32(0); // minutes past midnight
            await blockStream.WriteLittleEndianInt32(0); // ticks (1/50 sec) past last minute

            // filesystem creation date
            await blockStream.WriteLittleEndianInt32(days); // days since 1 jan 78
            await blockStream.WriteLittleEndianInt32(minutes); // minutes past midnight
            await blockStream.WriteLittleEndianInt32(ticks); // ticks (1/50 sec) past last minute
            
            blockStream.Seek(504, SeekOrigin.Begin);
            await blockStream.WriteLittleEndianInt32(0); // FFS: first directory cache block, 0 otherwise
            await blockStream.WriteLittleEndianInt32(1); // block secondary type = ST_ROOT (value 1)
            
            // calculate and update checksum
            var rootBlockBytes = blockStream.ToArray();
            await ChecksumHelper.UpdateChecksum(rootBlockBytes, 20);

            return rootBlockBytes;
        }
        
        protected async Task<byte[]> CreateExpectedBitmapBlockBytes()
        {
            var blockStream = new MemoryStream(new byte[512]);

            await blockStream.WriteLittleEndianInt32(0); // dummy checksum
            
            // free blocks
            var freeSectorBytes = new byte[] { 0xff, 0xff, 0xff, 0xff };
            for (var i = 0; i < 27; i++)
            {
                await blockStream.WriteBytes(freeSectorBytes);
            }
            
            // 27 * 32 + 14
            
            // allocated blocks
            // bits: 11111111111111110011111111111111
            var rootBitmapBytes = new byte[] { 0xff, 0xff, 0x3f, 0xff };
            await blockStream.WriteBytes(rootBitmapBytes);
            
            // free sectors
            for (var i = 0; i < 27; i++)
            {
                await blockStream.WriteBytes(freeSectorBytes);
            }
            
            // unused bytes
            for (var i = 0; i < 72; i++)
            {
                await blockStream.WriteLittleEndianInt32(0);
            }

            // calculate and update checksum
            var bitmapBytes = blockStream.ToArray();
            await ChecksumHelper.UpdateChecksum(bitmapBytes, 0);

            return bitmapBytes;            
        }
    }
}