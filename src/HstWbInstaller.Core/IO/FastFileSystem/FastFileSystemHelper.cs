namespace HstWbInstaller.Core.IO.FastFileSystem
{
    using System;
    using System.Collections.Generic;
    using System.IO;
    using System.Linq;
    using System.Text.RegularExpressions;
    using System.Threading.Tasks;
    using Extensions;

    public static class FastFileSystemHelper
    {
        public static async Task<IEnumerable<RootBlock>> FindRootBlocks(Stream stream)
        {
            var rootBlocks = new List<RootBlock>();
            
            var buffer = new byte[512];
            int bytesRead;
            do
            {
                var offset = stream.Position == 0 ? 0 : stream.Position / 512;
                bytesRead = await stream.ReadAsync(buffer, 0, buffer.Length);

                if (bytesRead != 512)
                {
                    continue;
                }

                var blockStream = new MemoryStream(buffer);
                var type = await blockStream.ReadInt32();
                var headerKey = await blockStream.ReadInt32();
                var highSeq = await blockStream.ReadInt32();
                var hashtableSize = await blockStream.ReadInt32();
                var firstData = await blockStream.ReadInt32();

                if (type != 2 || headerKey != 0 || highSeq != 0 || hashtableSize != Constants.HT_SIZE || firstData != 0)
                {
                    continue;
                }

                var rootBlock = await RootBlockReader.Parse(buffer);
                rootBlock.Offset = (uint)offset;
                
                rootBlocks.Add(rootBlock);
            } while (bytesRead == buffer.Length);

            return rootBlocks;
        }

        /// <summary>
        /// extract volume recursively
        /// </summary>
        /// <param name="volume"></param>
        /// <param name="outputPath"></param>
        public static async Task ExtractVolume(Volume volume,
            string outputPath)
        {
            var entries = (await Directory.AdfGetRDirEnt(volume, volume.RootBlock, true)).ToList();

            await ExtractDirectory(volume, volume.RootBlock, entries, volume.RootBlock.DiskName);

            await System.IO.File.WriteAllLinesAsync(Path.Combine(outputPath, string.Concat(volume.RootBlock.DiskName, " log.txt")), volume.Logs);
        }

        public static readonly Regex EntryRegex = new("[^\\w\\-_\\.\\\\/ ]", RegexOptions.Compiled | RegexOptions.IgnoreCase);

        /// <summary>
        /// extract directory recursively
        /// </summary>
        /// <param name="volume"></param>
        /// <param name="parent"></param>
        /// <param name="entries"></param>
        /// <param name="outputPath"></param>
        private static async Task ExtractDirectory(Volume volume, EntryBlock parent, IEnumerable<Entry> entries, string outputPath)
        {
            if (!System.IO.Directory.Exists(outputPath))
            {
                System.IO.Directory.CreateDirectory(outputPath);
            }

            foreach (var entry in entries)
            {
                var entryPath = Path.Combine(outputPath, entry.Name);
                volume.Logs.Add($"INFO: Extract file '{entryPath}'");

                entryPath = EntryRegex.Replace(entryPath, "_");

                if (entry.Type == Entry.EntryType.Dir)
                {
                    await ExtractDirectory(volume, entry.EntryBlock, entry.SubDir, entryPath);
                    continue;
                }

                var entryStream = await File.Open(volume, parent, entry.Name, FileMode.Read);

                if (entryStream == null)
                {
                    continue;
                }

                await using var fileStream = System.IO.File.OpenWrite(entryPath);

                var buffer = new byte[512];

                int bytesRead;
                do
                {
                    bytesRead = await entryStream.ReadAsync(buffer, 0, buffer.Length);
                    await fileStream.WriteAsync(buffer, 0, bytesRead);
                } while (bytesRead == buffer.Length);

                fileStream.Close();
                await fileStream.DisposeAsync();

                var fileInfo = new FileInfo(entryPath)
                {
                    CreationTimeUtc = entry.Date,
                    LastAccessTimeUtc = entry.Date,
                    LastWriteTimeUtc = entry.Date
                };
            }
        }

        /// <summary>
        /// mount fast file system volume from adf stream.
        /// </summary>
        /// <param name="stream">Stream to mount</param>
        /// <returns></returns>
        /// <exception cref="IOException"></exception>
        public static async Task<Volume> MountAdf(Stream stream)
        {
            var adfSize = stream.Length;
            if (adfSize == FloppyDiskConstants.DoubleDensity.Size)
            {
                return await Mount(stream, FloppyDiskConstants.DoubleDensity.LowCyl,
                    FloppyDiskConstants.DoubleDensity.HighCyl, FloppyDiskConstants.DoubleDensity.Heads,
                    FloppyDiskConstants.DoubleDensity.Sectors);
            }
            
            if (adfSize == FloppyDiskConstants.HighDensity.Size)
            {
                return await Mount(stream, FloppyDiskConstants.HighDensity.LowCyl,
                    FloppyDiskConstants.HighDensity.HighCyl, FloppyDiskConstants.HighDensity.Heads,
                    FloppyDiskConstants.HighDensity.Sectors);
            }

            throw new IOException($"Invalid adf size '{adfSize}'");
        }
        
        /// <summary>
        /// mount fast file system volume from single hdf partition.
        /// </summary>
        /// <param name="stream">Stream to mount</param>
        /// <param name="size">Size of hdf file</param>
        /// <param name="reserved">Number of reserved blocks</param>
        /// <param name="blockSize">Size of blocks in bytes</param>
        /// <param name="rootBlockOffset">Root block offset</param>
        /// <returns></returns>
        public static async Task<Volume> MountHdf(Stream stream, uint size, uint reserved = 0, uint blockSize = 512,
            uint rootBlockOffset = 0)
        {
            var blocks = size / blockSize;
            var surfaces = 16U; // heads
            var blocksPerTrack = 63U; // surfaces
            var blocksPerCylinder = surfaces * blocksPerTrack;
            var lowCyl = 0U;
            var highCyl = Convert.ToUInt32(Math.Ceiling((double)blocks / blocksPerCylinder));

            return await Mount(stream, lowCyl, highCyl, surfaces, blocksPerTrack, reserved, blockSize,
                rootBlockOffset);
        }

        /// <summary>
        /// mount fast file system volume.
        /// </summary>
        /// <param name="stream">Stream to mount</param>
        /// <param name="lowCyl"></param>
        /// <param name="highCyl"></param>
        /// <param name="surfaces"></param>
        /// <param name="blocksPerTrack"></param>
        /// <param name="reserved"></param>
        /// <param name="blockSize"></param>
        /// <param name="rootBlockOffset"></param>
        /// <returns></returns>
        public static async Task<Volume> Mount(Stream stream, uint lowCyl, uint highCyl, uint surfaces,
            uint blocksPerTrack, uint reserved = 0, uint blockSize = 512, uint rootBlockOffset = 0)
        {
            var cylinders = highCyl - lowCyl + 1;
            var blocksPerCylinder = surfaces * blocksPerTrack;
            var blocks = cylinders * blocksPerCylinder;
            var partitionStartOffset = lowCyl * blocksPerCylinder * blockSize;

            // if (adfReadBootBlock(vol, &boot)!=RC_OK) {
            //     (*adfEnv.wFct)("adfMount : BootBlock invalid");
            //     return NULL;
            // }       
            stream.Seek(partitionStartOffset, SeekOrigin.Begin);
            var bootBlockBytes = await stream.ReadBytes((int)blockSize);

            // vol->dosType = boot.dosType[3];
            var dosType = (int)bootBlockBytes[3];
            var dataBlockSize = Macro.isFFS(dosType) ? 512 : 488;

            // calculate root block offset, if not set
            if (rootBlockOffset == 0)
            {
                rootBlockOffset =
                    OffsetHelper.CalculateRootBlockOffset(lowCyl, highCyl, reserved, surfaces, blocksPerTrack);
            }

            // seek root block offset
            stream.Seek(partitionStartOffset + (rootBlockOffset * blockSize), SeekOrigin.Begin);
            var rootBlockBytes = await stream.ReadBytes((int)blockSize);

            // parse root block bytes
            var rootBlock = await RootBlockReader.Parse(rootBlockBytes);
            rootBlock.Offset = rootBlockOffset;
            rootBlock.HeaderKey = (int)rootBlockOffset;
            
            var volume = new Volume
            {
                PartitionStartOffset = lowCyl * blocksPerCylinder * blockSize,
                DosType = dosType,
                DataBlockSize = dataBlockSize,
                RootBlock = rootBlock,
                Blocks = blocks,
                Stream = stream,
                Reserved = reserved,
                BlockSize = blockSize,
                FirstBlock = reserved,
                LastBlock = blocks - 1,
                Mounted = true
            };

            await Bitmap.AdfReadBitmap(volume, (int)blocks, rootBlock);
            
            return volume;
        }
    }
}