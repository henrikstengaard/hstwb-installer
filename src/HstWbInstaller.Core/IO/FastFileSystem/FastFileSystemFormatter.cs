namespace HstWbInstaller.Core.IO.FastFileSystem
{
    using System.IO;
    using System.Linq;
    using System.Threading.Tasks;
    using Extensions;
    using RigidDiskBlocks;

    public static class FastFileSystemFormatter
    {
        /// <summary>
        /// format partition with fast file system
        /// </summary>
        public static async Task FormatPartition(Stream stream, PartitionBlock partitionBlock,
            string diskName)
        {
            // create root block
            var rootBlock = BlockHelper.CreateRootBlock(partitionBlock.LowCyl,
                partitionBlock.HighCyl,
                partitionBlock.Surfaces,
                partitionBlock.BlocksPerTrack,
                partitionBlock.Reserved,
                partitionBlock.FileSystemBlockSize, diskName);

            // calculate partition start offset
            var partitionStartByteOffset = partitionBlock.LowCyl * partitionBlock.Surfaces *
                                           partitionBlock.BlocksPerTrack *
                                           partitionBlock.FileSystemBlockSize;

            // write dos type at partition start
            stream.Seek(partitionStartByteOffset, SeekOrigin.Begin);
            await stream.WriteBytes(partitionBlock.DosType);
            
            // build root block bytes
            var rootBlockBytes = await RootBlockWriter.BuildBlock(rootBlock, partitionBlock.FileSystemBlockSize);

            // write root block
            var rootBlockByteOffset = partitionStartByteOffset + rootBlock.Offset * partitionBlock.FileSystemBlockSize;
            stream.Seek(rootBlockByteOffset, SeekOrigin.Begin);
            await stream.WriteBytes(rootBlockBytes);

            // write bitmap blocks
            foreach (var bitmapBlock in rootBlock.BitmapBlocks)
            {
                // seek bitmap block offset
                var bitmapBlockByteOffset = partitionStartByteOffset +
                                            bitmapBlock.Offset * partitionBlock.FileSystemBlockSize;
                stream.Seek(bitmapBlockByteOffset, SeekOrigin.Begin);

                // build and write bitmap block
                var bitmapBlockBytes = await BitmapBlockWriter.BuildBlock(bitmapBlock);
                await stream.WriteBytes(bitmapBlockBytes);
            }

            if (!rootBlock.BitmapExtensionBlocks.Any())
            {
                return;
            }

            // write bitmap extension blocks
            foreach (var bitmapExtensionBlock in rootBlock.BitmapExtensionBlocks)
            {
                // seek bitmap extension block offset
                var bitmapExtensionBlockByteOffset = partitionStartByteOffset +
                                                     bitmapExtensionBlock.Offset *
                                                     partitionBlock.FileSystemBlockSize;
                stream.Seek(bitmapExtensionBlockByteOffset, SeekOrigin.Begin);

                // build and write bitmap extension block
                var bitmapExtensionBlockBytes =
                    await BitmapExtensionBlockWriter.BuildBlock(bitmapExtensionBlock,
                        partitionBlock.FileSystemBlockSize);
                await stream.WriteBytes(bitmapExtensionBlockBytes);

                // write bitmap blocks
                foreach (var bitmapBlock in bitmapExtensionBlock.BitmapBlocks)
                {
                    // seek bitmap block offset
                    var bitmapBlockByteOffset = partitionStartByteOffset +
                                                bitmapBlock.Offset *
                                                partitionBlock.FileSystemBlockSize;
                    stream.Seek(bitmapBlockByteOffset, SeekOrigin.Begin);

                    // build and write bitmap block
                    var bitmapBlockBytes = await BitmapBlockWriter.BuildBlock(bitmapBlock);
                    await stream.WriteBytes(bitmapBlockBytes);
                }
            }
        }
    }
}