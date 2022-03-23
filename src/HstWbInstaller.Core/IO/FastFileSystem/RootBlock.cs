namespace HstWbInstaller.Core.IO.FastFileSystem
{
    using System;
    using System.IO;
    using System.Linq;
    using System.Threading.Tasks;
    using Extensions;
    using RigidDiskBlocks;

    public class RootBlock
    {
        public byte[] BlockBytes { get; set; }
        public int Checksum { get; set; }
        
        public uint Type { get; set; }
        public uint HashtableSize { get; set; }
        public int BitmapFlags { get; set; }
        public uint BitmapBlocksOffset { get; set; }
        public string DiskName { get; set; }
        public DateTime RootAlterationDate { get; set; }
        public DateTime DiskAlterationDate { get; set; }
        public DateTime FileSystemCreationDate { get; set; }
        
        // FFS: first directory cache block, 0 otherwise
        public uint FirstDirectoryCacheBlock { get; set; }
        
        // block secondary type = ST_ROOT (value 1)
        public uint BlockSecondaryType { get; set; }

        public RootBlock()
        {
            Type = 2;
            HashtableSize = 0x48;
            BitmapFlags = -1;
            FirstDirectoryCacheBlock = 0;
            BlockSecondaryType = 1;

            var now = DateTime.UtcNow;
            RootAlterationDate = now;
            FileSystemCreationDate = now;
        }
    }

    public static class FastFileSystemStreamExtensions
    {
        /// <summary>
        /// formats fast file system
        /// </summary>
        public static async Task FormatFastFileSystem(this Stream stream, PartitionBlock partitionBlock, string diskName)
        {
            var partitionStartByteOffset = partitionBlock.LowCyl * partitionBlock.Surfaces * partitionBlock.BlocksPerTrack *
                               partitionBlock.FileSystemBlockSize;
            stream.Seek(partitionStartByteOffset, SeekOrigin.Begin);
            await stream.WriteBytes(partitionBlock.DosType);
            
            var rootBlockOffset = FastFileSystemBlockHelper.CalculateRootBlockOffset(
                partitionBlock.LowCyl,
                partitionBlock.HighCyl,
                partitionBlock.Reserved,
                partitionBlock.Surfaces,
                partitionBlock.BlocksPerTrack);
            var rootBlockByteOffset = partitionStartByteOffset + rootBlockOffset * partitionBlock.FileSystemBlockSize;

            var rootBlock = new RootBlock
            {
                DiskName = diskName,
                BitmapBlocksOffset = rootBlockOffset + 1U
            };
            var rootBlockBytes = await RootBlockWriter.BuildBlock(rootBlock, partitionBlock.FileSystemBlockSize);
            
            stream.Seek(rootBlockByteOffset, SeekOrigin.Begin);
            await stream.WriteBytes(rootBlockBytes);

            // bitmap blocks
            
            var cylinders = partitionBlock.HighCyl - partitionBlock.LowCyl + 1;
            var blocks = cylinders * partitionBlock.Surfaces * partitionBlock.BlocksPerTrack;
            
            var mapsPerBitmapBlocks = Convert.ToInt32((partitionBlock.FileSystemBlockSize - Constants.CHECKSUM_SIZE) / 4 * 32);
            var bitmapBlocks = Convert.ToInt32(Math.Ceiling((double)blocks / mapsPerBitmapBlocks)) + 1;
            
            // build blocks free
            var blocksFree = new bool[blocks];
            for (var i = 0; i < blocks; i++)
            {
                if (i >= rootBlockOffset && i <= rootBlockOffset + bitmapBlocks)
                {
                    blocksFree[i] = false;
                    continue;
                }

                blocksFree[i] = true;
            }

            var b = blocksFree.ChunkBy(mapsPerBitmapBlocks).Select(x => new BitmapBlock
            {
                BlockFree = x.ToArray()
            });

            var bitmapBlockByteOffset = partitionStartByteOffset + rootBlock.BitmapBlocksOffset * partitionBlock.FileSystemBlockSize;
            stream.Seek(bitmapBlockByteOffset, SeekOrigin.Begin);
            foreach (var x in b)
            {
                var bitmapBlockBytes = await BitmapBlockWriter.BuildBlock(x);
                await stream.WriteBytes(bitmapBlockBytes);
            }
        }
    }
}