namespace HstWbInstaller.Core.IO.RigidDiskBlocks
{
    using System;
    using System.IO;
    using System.Linq;
    using System.Threading.Tasks;
    using Extensions;

    public static class BlockHelper
    {
        public static async Task<byte[]> ReadBlock(Stream stream)
        {
            var blockStartLength = 8;
            var blockStartBytes = await stream.ReadBytes(blockStartLength);
            var identifier = LittleEndianConverter.ConvertToAsciiString(blockStartBytes.CopyBytes(0, 4));
            var size = LittleEndianConverter.ConvertToUInt32(blockStartBytes.CopyBytes(4, 4));

            var blockBytes = new byte[size * 4];
            Array.Copy(blockStartBytes, 0, blockBytes, 0, blockStartLength);

            var bytesRead = await stream.ReadAsync(blockBytes, blockStartLength, blockBytes.Length - blockStartLength);
            if (bytesRead != blockBytes.Length - blockStartLength)
            {
                throw new IOException("Failed to read block");
            }

            return blockBytes;
        }

        public static FileSystemHeaderBlock CreateFileSystemHeaderBlock(byte[] dosType, int version, int revision,
            byte[] fileSystemBytes)
        {
            var maxSize = 512 - (5 * 4);
            var loadSegBlocks = fileSystemBytes.ChunkBy(maxSize).Select(x => CreateLoadSegBlock(x.ToArray()));

            return new FileSystemHeaderBlock
            {
                DosType = dosType,
                Version = (uint)((version << 16) | revision),
                LoadSegBlocks = loadSegBlocks.ToList()
            };
        }

        public static LoadSegBlock CreateLoadSegBlock(byte[] data)
        {
            return new LoadSegBlock
            {
                Data = data
            };
        }

        /// <summary>
        /// update block pointers to maintain rigid disk block structure. required when changes to rigid disk block needs block pointers updated like adding or deleting partition blocks
        /// </summary>
        /// <param name="rigidDiskBlock"></param>
        public static void UpdateBlockPointers(RigidDiskBlock rigidDiskBlock)
        {
            var highRsdkBlock = rigidDiskBlock.RdbBlockLo;

            var partitionBlocks = rigidDiskBlock.PartitionBlocks.ToList();
            
            var rigidDiskBlockIndex = rigidDiskBlock.RdbBlockLo;
            var partitionBlockIndex = partitionBlocks.Count > 0 ? rigidDiskBlockIndex + 1 : BlockIdentifiers.EndOfBlock;

            var partitionsChanged = rigidDiskBlock.PartitionList != partitionBlockIndex;

            rigidDiskBlock.PartitionList = partitionBlockIndex;
            
            for (var p = 0; p < partitionBlocks.Count; p++)
            {
                var partitionBlock = partitionBlocks[p];

                var nextPartitionBlock = p < partitionBlocks.Count - 1
                    ? (uint)(partitionBlockIndex + p + 1)
                    : BlockIdentifiers.EndOfBlock;

                if (partitionBlock.NextPartitionBlock != nextPartitionBlock)
                {
                    partitionsChanged = true;
                }

                partitionBlock.NextPartitionBlock = nextPartitionBlock;

                if (partitionBlockIndex + p > highRsdkBlock)
                {
                    highRsdkBlock = (uint)(partitionBlockIndex + p);
                }
            }

            if (partitionsChanged)
            {
                ResetFileSystemHeaderBlockPointers(rigidDiskBlock);
                ResetBadBlockPointers(rigidDiskBlock);
            }

            var fileSystemHeaderBlocks = rigidDiskBlock.FileSystemHeaderBlocks.ToList();
            var fileSystemHeaderBlockIndex = fileSystemHeaderBlocks.Count > 0 ? highRsdkBlock + 1 : BlockIdentifiers.EndOfBlock;
            
            var fileSystemHeaderChanged = rigidDiskBlock.FileSysHdrList != fileSystemHeaderBlockIndex;

            if (fileSystemHeaderChanged)
            {
                ResetBadBlockPointers(rigidDiskBlock);
            }
            
            rigidDiskBlock.FileSysHdrList = fileSystemHeaderBlockIndex;

            for (var f = 0; f < fileSystemHeaderBlocks.Count; f++)
            {
                var fileSystemHeaderBlock = fileSystemHeaderBlocks[f];
                var loadSegBlocks = fileSystemHeaderBlock.LoadSegBlocks.ToList();

                fileSystemHeaderBlock.NextFileSysHeaderBlock = f < fileSystemHeaderBlocks.Count - 1
                    ? (uint)(fileSystemHeaderBlockIndex + f + 1 + loadSegBlocks.Count)
                    : BlockIdentifiers.EndOfBlock;
                fileSystemHeaderBlock.SegListBlocks = (int)(fileSystemHeaderBlockIndex + f + 1);

                if (fileSystemHeaderBlockIndex + f + loadSegBlocks.Count > highRsdkBlock)
                {
                    highRsdkBlock = (uint)(fileSystemHeaderBlockIndex + f + loadSegBlocks.Count);
                }

                for (var l = 0; l < loadSegBlocks.Count; l++)
                {
                    var loadSegBlock = loadSegBlocks[l];

                    loadSegBlock.NextLoadSegBlock = l < loadSegBlocks.Count - 1
                        ? (int)(fileSystemHeaderBlockIndex + f + 2 + l)
                        : -1;
                }
            }

            var badBlocks = rigidDiskBlock.BadBlocks.ToList();
            var badBlockIndex = badBlocks.Count > 0 ? highRsdkBlock + 1 : BlockIdentifiers.EndOfBlock;
            rigidDiskBlock.BadBlockList = badBlockIndex;

            for (var b = 0; b < badBlocks.Count; b++)
            {
                var badBlock = badBlocks[b];
                
                badBlock.NextBadBlock = b < badBlocks.Count - 1
                    ? (uint)(badBlockIndex + b + 1)
                    : BlockIdentifiers.EndOfBlock;
                
                // update highest used rdb block
                if (badBlockIndex + b > highRsdkBlock)
                {
                    highRsdkBlock = (uint)(badBlockIndex + b);
                }
            }

            // set highest used rdb block
            rigidDiskBlock.HighRsdkBlock = highRsdkBlock;
        }

        public static void ResetRigidDiskBlockPointers(RigidDiskBlock rigidDiskBlock)
        {
            ResetPartitionBlockPointers(rigidDiskBlock);
            ResetFileSystemHeaderBlockPointers(rigidDiskBlock);
            ResetBadBlockPointers(rigidDiskBlock);
        }

        public static void ResetPartitionBlockPointers(RigidDiskBlock rigidDiskBlock)
        {
            rigidDiskBlock.PartitionList = 0;

            foreach (var partitionBlock in rigidDiskBlock.PartitionBlocks)
            {
                ResetPartitionBlockPointers(partitionBlock);
            }
        }

        public static void ResetPartitionBlockPointers(PartitionBlock partitionBlock)
        {
            partitionBlock.NextPartitionBlock = 0;
        }

        public static void ResetFileSystemHeaderBlockPointers(RigidDiskBlock rigidDiskBlock)
        {
            rigidDiskBlock.FileSysHdrList = 0;

            foreach (var fileSystemHeaderBlock in rigidDiskBlock.FileSystemHeaderBlocks)
            {
                ResetFileSystemHeaderBlockPointers(fileSystemHeaderBlock);
            }
        }

        public static void ResetFileSystemHeaderBlockPointers(FileSystemHeaderBlock fileSystemHeaderBlock)
        {
            fileSystemHeaderBlock.NextFileSysHeaderBlock = 0;
            fileSystemHeaderBlock.SegListBlocks = 0;

            foreach (var loadSegBlock in fileSystemHeaderBlock.LoadSegBlocks)
            {
                ResetLoadSegBlockPointers(loadSegBlock);
            }
        }

        public static void ResetLoadSegBlockPointers(LoadSegBlock loadSegBlock)
        {
            loadSegBlock.NextLoadSegBlock = 0;
        }

        public static void ResetBadBlockPointers(RigidDiskBlock rigidDiskBlock)
        {
            rigidDiskBlock.BadBlockList = 0;

            foreach (var badBlock in rigidDiskBlock.BadBlocks)
            {
                ResetBadBlockPointers(badBlock);
            }
        }
        
        public static void ResetBadBlockPointers(BadBlock badBlock)
        {
            badBlock.NextBadBlock = 0;
        }
    }
}