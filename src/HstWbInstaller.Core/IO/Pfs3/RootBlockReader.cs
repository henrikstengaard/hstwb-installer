﻿namespace HstWbInstaller.Core.IO.Pfs3
{
    using System.IO;
    using System.Threading.Tasks;
    using Extensions;
    using RigidDiskBlocks;

    // https://github.com/tonioni/pfs3aio
    public class RootBlockReader
    {
        public static async Task<RootBlock> Parse(byte[] blockBytes)
        {
            var blockStream = new MemoryStream(blockBytes);
            
            var diskType = await blockStream.ReadInt32();
            if (diskType != 0x50465301)
            {
                throw new IOException("Invalid root block");
            }

            var options = await blockStream.ReadUInt32();
            var datestamp = await blockStream.ReadUInt32(); /* current datestamp */
            var creationDay = await blockStream.ReadUInt16(); /* days since Jan. 1, 1978 (like ADOS; WORD instead of LONG) */
            var creationMinute = await blockStream.ReadUInt16(); /* minutes past modnight            */
            var creationTick = await blockStream.ReadUInt16(); /* ticks past minute                */
            var protection = await blockStream.ReadUInt16(); /* protection bits (ala ADOS)       */
            var diskNameLength = blockStream.ReadByte(); /* disk label (pascal string)       */
            var diskNameBytes = await blockStream.ReadBytes(31);
            var diskName = LittleEndianConverter.ConvertToIso88591String(diskNameBytes, diskNameLength);
            var lastReserved = await blockStream.ReadUInt32(); /* reserved area. sector number of last reserved block */
            var firstReserved = await blockStream.ReadUInt32(); /* sector number of first reserved block */
            var reservedFree = await blockStream.ReadUInt32(); /* number of reserved blocks (blksize blocks) free  */
            var reservedBlkSize = await blockStream.ReadUInt16(); /* size of reserved blocks in bytes */
            var rBlkCluster = await blockStream.ReadUInt16(); /* number of sectors in rootblock, including bitmap  */
            var blocksFree = await blockStream.ReadUInt32(); /* blocks free                      */
            var alwaysFree = await blockStream.ReadUInt32(); /* minimum number of blocks free    */
            var rovingPtr = await blockStream.ReadUInt32(); /* current LONG bitmapfield nr for allocation       */
            var delDir = await blockStream.ReadUInt32(); /* deldir location (<= 17.8)        */
            var diskSize = await blockStream.ReadUInt32(); /* disksize in sectors              */
            var extension = await blockStream.ReadUInt32(); /* rootblock extension (16.4)       offset=88 $58 */
            var notUsed = await blockStream.ReadUInt32();
            
            return new RootBlock
            {
                DiskName = diskName,
                BlocksFree = blocksFree,
                AlwaysFree = alwaysFree,
                DiskSize = diskSize
            };
        }
    }
}