namespace HstWbInstaller.Core.IO.RigidDiskBlocks
{
    using System;
    using System.Collections.Generic;
    using System.IO;
    using System.Linq;
    using System.Threading.Tasks;
    using Extensions;

    public static class BadBlockReader
    {
        public static async Task<IEnumerable<BadBlock>> Read(RigidDiskBlock rigidDiskBlock, Stream stream)
        {
            if (rigidDiskBlock == null) throw new ArgumentNullException(nameof(rigidDiskBlock));
            if (stream == null) throw new ArgumentNullException(nameof(stream));

            if (rigidDiskBlock.BadBlockList == BlockIdentifiers.EndOfBlock)
            {
                return Enumerable.Empty<BadBlock>();
            }
            
            var badBlocks = new List<BadBlock>();
            
            var badBlockList = rigidDiskBlock.BadBlockList;
            
            do
            {
                // calculate block offset
                var blockOffset = rigidDiskBlock.BlockSize * badBlockList;

                // seek block offset
                stream.Seek(blockOffset, SeekOrigin.Begin);

                // read block
                var block = await BlockHelper.ReadBlock(stream);

                // read rigid disk block
                var badBlock = await Parse(block);
                
                badBlocks.Add(badBlock);
                
                // get next partition list block and increase partition number
                badBlockList = badBlock.NextBadBlock;
            } while (badBlockList > 0 && badBlockList != BlockIdentifiers.EndOfBlock);

            return badBlocks;
        }

        public static async Task<BadBlock> Parse(byte[] blockBytes)
        {
            var blockStream = new MemoryStream(blockBytes);

            var identifier = await blockStream.ReadAsciiString(); // Identifier 32 bit word : 'BADB'
            if (!identifier.Equals(BlockIdentifiers.BadBlock))
            {
                throw new IOException("Invalid bad block identifier");
            }
            
            await blockStream.ReadUInt32(); // Size of the structure for checksums
            var checksum = await blockStream.ReadInt32(); // Checksum of the structure
            var hostId = await blockStream.ReadUInt32(); // SCSI Target ID of host, not really used
            var nextBadBlock = await blockStream.ReadUInt32(); // next BadBlock block

            var calculatedChecksum = await ChecksumHelper.CalculateChecksum(blockBytes, 8);

            if (checksum != calculatedChecksum)
            {
                throw new IOException("Invalid bad block checksum");
            }
            
            var data = await blockStream.ReadBytes(((blockBytes.Length / 4) - 6) / 2);

            return new BadBlock
            {
                BlockBytes = blockBytes,
                Checksum = checksum,
                HostId = hostId,
                NextBadBlock = nextBadBlock,
                Data = data
            };
        }
    }
}