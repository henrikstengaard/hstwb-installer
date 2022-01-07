namespace HstWbInstaller.Core.IO.RigidDiskBlocks
{
    using System.Collections.Generic;
    using System.IO;
    using System.Linq;
    using System.Threading.Tasks;

    public class RigidDiskBlockReader
    {
        private readonly Stream stream;

        public RigidDiskBlockReader(Stream stream)
        {
            this.stream = stream;
        }

        public async Task<RigidDiskBlock> Read(bool throwException = true)
        {
            var block = 0;
            var blockSize = 512;
            var rdbLocationLimit = 16;
            RigidDiskBlock rigidDiskBlock;

            // read rigid disk block from one of the first 15 blocks
            do
            {
                // calculate block offset
                var blockOffset = blockSize * block;

                // seek block offset
                stream.Seek(blockOffset, SeekOrigin.Begin);

                // read rigid disk block
                rigidDiskBlock = await ReadRigidDiskBlock();

                block++;
            } while (block < rdbLocationLimit && rigidDiskBlock == null);
            
            // fail, if rigid disk block is null
            if (rigidDiskBlock == null)
            {
                if (throwException)
                {
                    throw new IOException("Invalid rigid disk block");
                }

                return null;
            }

            // get partition list block and set partition number to 1
            var partitionList = rigidDiskBlock.PartitionList;

            var partitionBlocks = new List<PartitionBlock>();
            
            do
            {
                // calculate partition block offset
                var partitionBlockOffset = rigidDiskBlock.BlockSize * partitionList;

                // seek partition block offset
                stream.Seek(partitionBlockOffset, SeekOrigin.Begin);

                // read partition block
                var partitionBlock = await ReadPartitionBlock(rigidDiskBlock);

                // fail, if partition block is null
                if (partitionBlock == null)
                {
                    throw new IOException("Invalid partition block");
                }
                
                partitionBlocks.Add(partitionBlock);

                // get next partition list block and increase partition number
                partitionList = partitionBlock.NextPartitionBlock;
            } while (partitionList > 0 && partitionList != 4294967295);

            rigidDiskBlock.PartitionBlocks = partitionBlocks;
            
            return rigidDiskBlock;
        }

        private async Task<RigidDiskBlock> ReadRigidDiskBlock()
        {
            var magic = await stream.ReadMagic(); // Identifier 32 bit word : 'RDSK'
            if (!magic.Equals("RDSK"))
            {
                return null;
            }
            
            var size = await stream.ReadUInt32();// Size of the structure for checksums
            var checksum = await stream.ReadInt32(); // Checksum of the structure
            var hostId = await stream.ReadUInt32(); // SCSI Target ID of host, not really used
            var blockSize = await stream.ReadUInt32(); // Size of disk blocks
            var flags = await stream.ReadUInt32(); // RDB Flags
            var badBlockList = await stream.ReadUInt32(); // Bad block list
            var partitionList = await stream.ReadUInt32(); // Partition list
            var fileSysHdrList = await stream.ReadUInt32(); // File system header list
            var driveInitCode = await stream.ReadUInt32(); // Drive specific init code
            var bootBlockList = await stream.ReadUInt32(); // Amiga OS 4 Boot Blocks

            // read reserved, unused word, need to be set to $ffffffff
            for (var i = 0; i < 5; i++)
            {
                await stream.ReadBytes(4);
            }

            // physical drive characteristics
            var cylinders = await stream.ReadUInt32(); // Number of the cylinders of the drive
            var sectors = await stream.ReadUInt32(); // Number of sectors of the drive
            var heads = await stream.ReadUInt32(); // Number of heads of the drive
            var interleave = await stream.ReadUInt32(); // Interleave 
            var parkingZone = await stream.ReadUInt32(); // Head parking cylinder

            // read reserved, unused word, need to be set to $ffffffff
            for (var i = 0; i < 3; i++)
            {
                await stream.ReadBytes(4);
            }
            
            var writePreComp = await stream.ReadUInt32(); // Starting cylinder of write pre-compensation 
            var reducedWrite = await stream.ReadUInt32(); // Starting cylinder of reduced write current
            var stepRate = await stream.ReadUInt32(); // Step rate of the drive
            
            // read reserved, unused word, need to be set to $ffffffff
            for (var i = 0; i < 5; i++)
            {
                await stream.ReadBytes(4);
            }

            // logical drive characteristics
            var rdbBlockLo = await stream.ReadUInt32(); // low block of range reserved for hardblocks
            var rdbBlockHi = await stream.ReadUInt32(); // high block of range for these hardblocks
            var loCylinder = await stream.ReadUInt32(); // low cylinder of partitionable disk area
            var hiCylinder = await stream.ReadUInt32(); // high cylinder of partitionable data area
            var cylBlocks = await stream.ReadUInt32(); // number of blocks available per cylinder
            var autoParkSeconds = await stream.ReadUInt32(); // zero for no auto park
            var highRsdkBlock = await stream.ReadUInt32(); // highest block used by RDSK (not including replacement bad blocks)
            
            await stream.ReadBytes(4); // read reserved, unused word
            
            // drive identification
            var diskVendor = await stream.ReadString(8);
            var diskProduct = await stream.ReadString(16);
            var diskRevision = await stream.ReadString(4);
            var controllerVendor = await stream.ReadString(8);
            var controllerProduct = await stream.ReadString(16);
            var controllerRevision = await stream.ReadString(4);
            
            await stream.ReadBytes(4); // read reserved, unused word
            
            // calculate size of disk in bytes
            var diskSize = cylinders * heads * sectors * blockSize;
            
            return new RigidDiskBlock
            {
                Size = size,
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

        private async Task<PartitionBlock> ReadPartitionBlock(RigidDiskBlock rigidDiskBlock)
        {
            var magic = await stream.ReadMagic(); // Identifier 32 bit word : 'PART'
            if (!magic.Equals("PART"))
            {
                return null;
            }
            
            var size = await stream.ReadUInt32(); // Size of the structure for checksums
            var checksum = await stream.ReadInt32(); // Checksum of the structure
            var hostId = await stream.ReadUInt32(); // SCSI Target ID of host, not really used 
            var nextPartitionBlock = await stream.ReadUInt32(); // Block number of the next PartitionBlock
            var flags = await stream.ReadUInt32(); // Part Flags (NOMOUNT and BOOTABLE)

            // read reserved, unused word
            for (var i = 0; i < 2; i++)
            {
                await stream.ReadBytes(4);
            }
            
            var devFlags = await stream.ReadUInt32(); // Preferred flags for OpenDevice
            var driveNameLength = (await stream.ReadBytes(1)).FirstOrDefault(); //  Preferred DOS device name: BSTR form
            var driveName = await stream.ReadString(driveNameLength); // # Preferred DOS device name: BSTR form

            if (driveNameLength < 31)
            {
                await stream.ReadBytes(31 - driveNameLength);
            }

            // read reserved, unused word
            for (var i = 0; i < 15; i++)
            {
                await stream.ReadBytes(4);
            }
            
            var sizeOfVector = await stream.ReadUInt32(); // Size of Environment vector
            var sizeBlock = await stream.ReadUInt32(); // Size of the blocks in 32 bit words, usually 128
            var secOrg = await stream.ReadUInt32(); // Not used; must be 0
            var surfaces = await stream.ReadUInt32(); // Number of heads (surfaces)
            var sectors = await stream.ReadUInt32(); // Disk sectors per block, used with SizeBlock, usually 1
            var blocksPerTrack = await stream.ReadUInt32(); // Blocks per track. drive specific
            var reserved = await stream.ReadUInt32(); // DOS reserved blocks at start of partition.
            var preAlloc = await stream.ReadUInt32(); // DOS reserved blocks at end of partition
            var interleave = await stream.ReadUInt32(); // Not used, usually 0
            var lowCyl	= await stream.ReadUInt32(); // First cylinder of the partition
            var highCyl = await stream.ReadUInt32(); // Last cylinder of the partition
            var numBuffer = await stream.ReadUInt32(); // Initial # DOS of buffers.
            var bufMemType = await stream.ReadUInt32(); // Type of mem to allocate for buffers
            var maxTransfer = await stream.ReadUInt32(); // Max number of bytes to transfer at a time
            var mask = await stream.ReadUInt32(); // Address Mask to block out certain memory
            var bootPriority = await stream.ReadUInt32(); // Boot priority for autoboot
            var dosType = await stream.ReadBytes(4); // # Dostype of the file system
            var baud = await stream.ReadUInt32(); // Baud rate for serial handler
            var control = await stream.ReadUInt32(); // Control word for handler/filesystem 
            var bootBlocks = await stream.ReadUInt32(); // Number of blocks containing boot code 
            
            // read reserved, unused word
            for (var i = 0; i < 12; i++)
            {
                await stream.ReadBytes(4);
            }

            // calculate size of partition in bytes
            var partitionSize = (highCyl - lowCyl + 1) * surfaces * blocksPerTrack * rigidDiskBlock.BlockSize;

            return new PartitionBlock
            {
                Size = size,
                Checksum = checksum,
                HostId = hostId,
                NextPartitionBlock = nextPartitionBlock,
                Flags = flags,
                DevFlags = devFlags,
                DriveName = driveName,
                SizeOfVector = sizeOfVector,
                SizeBlock = sizeBlock,
                SecOrg = secOrg,
                Surfaces = surfaces,
                Sectors = sectors,
                BlocksPerTrack = blocksPerTrack,
                Reserved = reserved,
                PreAlloc = preAlloc,
                Interleave = interleave,
                LowCyl = lowCyl,
                HighCyl = highCyl,
                NumBuffer = numBuffer,
                BufMemType = bufMemType,
                MaxTransfer = maxTransfer,
                Mask = mask,
                BootPriority = bootPriority,
                DosType = dosType,
                Baud = baud,
                Control = control,
                BootBlocks = bootBlocks,
                PartitionSize = partitionSize
            };
        }
    }
}