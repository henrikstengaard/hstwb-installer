namespace HstWbInstaller.Core.IO.RigidDiskBlocks
{
    using System;
    using System.IO;
    using System.Threading.Tasks;
    using Extensions;

    // http://lclevy.free.fr/adflib/adf_info.html#p65
    // http://amigadev.elowar.com/read/ADCD_2.1/Devices_Manual_guide/node0079.html
    public static class RigidDiskBlockReader
    {
        public static async Task<RigidDiskBlock> Read(Stream stream)
        {
            var rdbIndex = 0;
            var blockSize = 512;
            var rdbLocationLimit = 16;
            RigidDiskBlock rigidDiskBlock;

            // read rigid disk block from one of the first 15 blocks
            do
            {
                // calculate block offset
                var blockOffset = blockSize * rdbIndex;

                // seek block offset
                stream.Seek(blockOffset, SeekOrigin.Begin);

                // read block
                var block = await BlockHelper.ReadBlock(stream);

                // read rigid disk block
                rigidDiskBlock = await Parse(block);

                rdbIndex++;
            } while (rdbIndex < rdbLocationLimit && rigidDiskBlock == null);

            // fail, if rigid disk block is null
            if (rigidDiskBlock == null)
            {
                return null;
            }

            rigidDiskBlock.PartitionBlocks = await PartitionBlockReader.Read(rigidDiskBlock, stream);
            rigidDiskBlock.BadBlocks = await BadBlockReader.Read(rigidDiskBlock, stream);

            return rigidDiskBlock;
        }

        public static async Task<RigidDiskBlock> Parse(byte[] blockBytes)
        {
            var blockStream = new MemoryStream(blockBytes);

            var magic = await blockStream.ReadAsciiString(); // Identifier 32 bit word : 'RDSK'
            if (!magic.Equals(BlockIdentifiers.RigidDiskBlock))
            {
                return null;
            }

            await blockStream.ReadUInt32(); // Size of the structure for checksums
            var checksum = await blockStream.ReadInt32(); // Checksum of the structure
            var hostId = await blockStream.ReadUInt32(); // SCSI Target ID of host, not really used
            var blockSize = await blockStream.ReadUInt32(); // Size of disk blocks
            var flags = await blockStream.ReadUInt32(); // RDB Flags
            var badBlockList = await blockStream.ReadUInt32(); // Bad block list
            var partitionList = await blockStream.ReadUInt32(); // Partition list
            var fileSysHdrList = await blockStream.ReadUInt32(); // File system header list
            var driveInitCode = await blockStream.ReadUInt32(); // Drive specific init code
            var bootBlockList = await blockStream.ReadUInt32(); // Amiga OS 4 Boot Blocks

            // skip reserved
            blockStream.Seek(4 * 5, SeekOrigin.Current);

            // physical drive characteristics
            var cylinders = await blockStream.ReadUInt32(); // Number of the cylinders of the drive
            var sectors = await blockStream.ReadUInt32(); // Number of sectors of the drive
            var heads = await blockStream.ReadUInt32(); // Number of heads of the drive
            var interleave = await blockStream.ReadUInt32(); // Interleave 
            var parkingZone = await blockStream.ReadUInt32(); // Head parking cylinder

            // skip reserved
            blockStream.Seek(4 * 3, SeekOrigin.Current);

            var writePreComp = await blockStream.ReadUInt32(); // Starting cylinder of write pre-compensation 
            var reducedWrite = await blockStream.ReadUInt32(); // Starting cylinder of reduced write current
            var stepRate = await blockStream.ReadUInt32(); // Step rate of the drive

            // skip reserved
            blockStream.Seek(4 * 5, SeekOrigin.Current);
            
            // logical drive characteristics
            var rdbBlockLo = await blockStream.ReadUInt32(); // low block of range reserved for hardblocks
            var rdbBlockHi = await blockStream.ReadUInt32(); // high block of range for these hardblocks
            var loCylinder = await blockStream.ReadUInt32(); // low cylinder of partitionable disk area
            var hiCylinder = await blockStream.ReadUInt32(); // high cylinder of partitionable data area
            var cylBlocks = await blockStream.ReadUInt32(); // number of blocks available per cylinder
            var autoParkSeconds = await blockStream.ReadUInt32(); // zero for no auto park
            var highRsdkBlock =
                await blockStream.ReadUInt32(); // highest block used by RDSK (not including replacement bad blocks)

            // skip reserved
            blockStream.Seek(4, SeekOrigin.Current);

            // drive identification
            var diskVendor = (await blockStream.ReadBytes(8)).ReadNullTerminatedString().Trim();
            var diskProduct = (await blockStream.ReadBytes(16)).ReadNullTerminatedString().Trim();
            var diskRevision = (await blockStream.ReadBytes(4)).ReadNullTerminatedString().Trim();
            var controllerVendor = (await blockStream.ReadBytes(8)).ReadNullTerminatedString().Trim();
            var controllerProduct = (await blockStream.ReadBytes(16)).ReadNullTerminatedString().Trim();
            var controllerRevision = (await blockStream.ReadBytes(4)).ReadNullTerminatedString().Trim();

            // skip reserved
            blockStream.Seek(4, SeekOrigin.Current);

            // calculate size of disk in bytes
            var diskSize = (long)cylinders * heads * sectors * blockSize;

            var calculatedChecksum = await BlockHelper.CalculateChecksum(blockBytes, 8);

            if (checksum != calculatedChecksum)
            {
                throw new Exception("Invalid rigid disk block checksum");
            }

            return new RigidDiskBlock
            {
                BlockBytes = blockBytes,
                Checksum = checksum,
                HostId = hostId,
                BlockSize = blockSize,
                Flags = flags,
                BadBlockList = badBlockList,
                PartitionList = partitionList,
                FileSysHdrList = fileSysHdrList,
                DriveInitCode = driveInitCode,
                BootBlockList = bootBlockList,
                Cylinders = cylinders,
                Sectors = sectors,
                Heads = heads,
                Interleave = interleave,
                ParkingZone = parkingZone,
                WritePreComp = writePreComp,
                ReducedWrite = reducedWrite,
                StepRate = stepRate,
                RdbBlockLo = rdbBlockLo,
                RdbBlockHi = rdbBlockHi,
                LoCylinder = loCylinder,
                HiCylinder = hiCylinder,
                CylBlocks = cylBlocks,
                AutoParkSeconds = autoParkSeconds,
                HighRsdkBlock = highRsdkBlock,
                DiskVendor = diskVendor,
                DiskProduct = diskProduct,
                DiskRevision = diskRevision,
                ControllerVendor = controllerVendor,
                ControllerProduct = controllerProduct,
                ControllerRevision = controllerRevision,
                DiskSize = diskSize
            };
        }
    }
}