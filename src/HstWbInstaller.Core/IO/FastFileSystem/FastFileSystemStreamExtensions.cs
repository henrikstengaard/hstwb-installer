namespace HstWbInstaller.Core.IO.FastFileSystem
{
    using System;
    using System.IO;
    using System.Linq;
    using System.Threading.Tasks;
    using Extensions;
    using RigidDiskBlocks;

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

            var rootBlock = new RootBlock
            {
                DiskName = diskName,
                BitmapBlocksOffset = rootBlockOffset + 1U,
                FirstDirectoryCacheBlock = rootBlockOffset + 1U
            };
            
            
            
            
            
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

            rootBlock.BitmapBlocks = blocksFree.ChunkBy(mapsPerBitmapBlocks).Select(x => new BitmapBlock
            {
                BlockFree = x.ToArray()
            });
            
            // build root block bytes
            var rootBlockBytes = await RootBlockWriter.BuildBlock(rootBlock, partitionBlock.FileSystemBlockSize);

            // write root block
            var rootBlockByteOffset = partitionStartByteOffset + rootBlockOffset * partitionBlock.FileSystemBlockSize;
            stream.Seek(rootBlockByteOffset, SeekOrigin.Begin);
            await stream.WriteBytes(rootBlockBytes);

            // write bitmap blocks
            var bitmapBlockByteOffset = partitionStartByteOffset + rootBlock.BitmapBlocksOffset * partitionBlock.FileSystemBlockSize;
            stream.Seek(bitmapBlockByteOffset, SeekOrigin.Begin);
            foreach (var bitmapBlock in rootBlock.BitmapBlocks)
            {
                var bitmapBlockBytes = await BitmapBlockWriter.BuildBlock(bitmapBlock);
                await stream.WriteBytes(bitmapBlockBytes);
            }
        }
    }
}