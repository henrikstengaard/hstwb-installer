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
        
        public static async Task<int> CalculateChecksum(byte[] blockBytes, int checksumOffset)
        {
            int checksum = 0;
            var memoryStream = new MemoryStream(blockBytes);
            for (var offset = 0; offset < blockBytes.Length; offset += 4)
            {
                var value = await memoryStream.ReadInt32();
                
                // skip checksum offset
                if (offset == checksumOffset)
                {
                    continue;
                }

                checksum += value;
            }

            checksum = -checksum;
            return checksum;
        }

        /// <summary>
        /// updates checksum for block bytes by calculating checksum and writing it at checksum offset
        /// </summary>
        /// <param name="blockBytes"></param>
        /// <param name="checksumOffset"></param>
        public static async Task UpdateChecksum(byte[] blockBytes, int checksumOffset)
        {
            var checksum = await CalculateChecksum(blockBytes, checksumOffset);
            var checksumBytes = LittleEndianConverter.ConvertToBytes(checksum);
            Array.Copy(checksumBytes, 0, blockBytes, checksumOffset, checksumBytes.Length);
        }
        
        public static async Task<FileSystemHeaderBlock> CreateFileSystemHeaderBlock(byte[] dosType, int majorVersion, int minorVersion, Stream stream)
        {
            await using var fileSystemStream = new MemoryStream();
            await stream.CopyToAsync(fileSystemStream);
            
            var maxSize = 512 - (5 * 4);

            var loadSegBlocks = fileSystemStream.ToArray().ChunkBy(maxSize).Select(x => CreateLoadSegBlock(x.ToArray()));

            return new FileSystemHeaderBlock
            {
                DosType = dosType,
                Version = (uint)((majorVersion << 16) | minorVersion),
                LoadSegBlocks = loadSegBlocks.ToList()
            };
        }

        public static LoadSegBlock CreateLoadSegBlock(byte[] data)
        {
            return new LoadSegBlock
            {
                Size = (uint)data.Length / 4 + 5,
                Data = data
            };
        }

    }
}