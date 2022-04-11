﻿namespace HstWbInstaller.Core.IO.Pfs3
{
    using System;
    using System.IO;
    using System.Threading.Tasks;
    using Blocks;
    using Extensions;
    using RigidDiskBlocks;

    public static class Format
    {
        public static async Task Pfs3Format(Stream stream, PartitionBlock partitionBlock, string diskName)
        {
            // format.c, FDSFormat()
            
            var g = new globaldata(stream)
            {
                NumBuffers = partitionBlock.NumBuffer,
                blocksize = partitionBlock.FileSystemBlockSize,
                TotalSectors = Convert.ToUInt32(Math.Ceiling((double)partitionBlock.PartitionSize / partitionBlock.FileSystemBlockSize))
            };
            
            /* remove error-induced soft protect */
            if (g.softprotect)
            {
                throw new IOException("ERROR_DISK_WRITE_PROTECTED");
            }

            if (g.softprotect && g.protectkey == ~0)
            {
                g.softprotect = false;
                g.protectkey = 0;
            }
                            
            /* update dos envec and geom */
            // GetDriveGeometry (g);
            // ShowVersion (g);

            /* issue 00118: disk cannot exceed MAX_DISK_SIZE */
            if (g.TotalSectors > Constants.MAXDISKSIZE)
            {
                throw new Exception("totalSectors: ERROR_OBJECT_TOO_LARGE");
            }

            // Only 512, 1024, 2048 and 4096 block sizes are supported.
            // Last two require new large partition mode.
            if (g.blocksize < 512 || g.blocksize > 4096)
            {
                throw new Exception("sectorSize: ERROR_BAD_NUMBER");
            }
            
            // calculate partition start offset
            var partitionStartByteOffset = partitionBlock.LowCyl * partitionBlock.Surfaces *
                                           partitionBlock.BlocksPerTrack *
                                           partitionBlock.FileSystemBlockSize;

            // write dos type at partition start
            stream.Seek(partitionStartByteOffset, SeekOrigin.Begin);
            await stream.WriteBytes(partitionBlock.DosType);
            
            /*
     * creates & writes the two bootblocks
     */
            var bootBlock1 = new BootBlock();
            var bootBlock1Bytes = await BootBlockWriter.MakeBootBlock(bootBlock1);
            await stream.WriteBytes(bootBlock1Bytes);
            //Disk.RawWrite(stream, bootBlock1Bytes, 1, Constants.BOOTBLOCK1, g);

            var bootBlock2Bytes = new byte[512];
            await stream.WriteBytes(bootBlock2Bytes);
            //Disk.RawWrite(stream, bootBlock2Bytes, 1, Constants.BOOTBLOCK2, g);

            // if (!(rootblock = MakeRootBlock (diskname, g))) {
            //     *error = ERROR_NO_FREE_STORE;
            //     return DOSFALSE;
            // }
            RootBlock rootBlock;
            if ((rootBlock = MakeRootBlock(diskName, g)) == null)
            {
                throw new Exception("ERROR_NO_FREE_STORE");
            }

            /*  make volumedata BEFORE rext ! (bug 00135) */
            // g->currentvolume = volume = MakeVolumeData (rootblock, g);
            volumedata volume;
            g.currentvolume = volume = Volume.MakeVolumeData(rootBlock, g);

            /* add extension */
            // if (!(rext = MakeFormatRBlkExtension (rootblock, g))) {
            //     *error = ERROR_NO_FREE_STORE;
            //     return DOSFALSE;			// rootblock extension could not be created
            // }
            g.currentvolume.rblkextension = MakeFormatRBlkExtension(rootBlock, g);
            rootBlock.Options |= RootBlock.DiskOptionsEnum.MODE_EXTENSION;
            
            Init.InitModules(g.currentvolume, true, g);

            MakeBitmap(g);

            uint i;
            do {
                i = anodes.AllocAnode(0, g);
            } while (i < Constants.ANODE_ROOTDIR - 1);

            MakeRootDir(g);
            
            // #if DELDIR
            //  /* add deldir */
            //  SetDeldir(2, g);
            //  rootblock->options |= MODE_DELDIR | MODE_SUPERDELDIR;
            //  g->dirty = TRUE;
            // #endif
            
            Directory.SetDeldir(2, g);
            rootBlock.Options |= RootBlock.DiskOptionsEnum.MODE_DELDIR | RootBlock.DiskOptionsEnum.MODE_SUPERDELDIR;
            g.dirty = true;

            //
            Update.UpdateDisk(g);
            Volume.FreeVolumeResources(volume, g);
            g.currentvolume = null;
            //
            // return DOSTRUE;
        }
        
        public static RootBlock MakeRootBlock(string diskName, globaldata g)
        {
            var rootBlock = new RootBlock
            {
                Datestamp = 1,
                CreationDate = DateTime.UtcNow,
                Protection = 0xf0,
                FirstReserved = 2,
                DiskName = diskName
            };

            // determine reserved blocksize
            uint resblocksize = 1024;
            if (g.TotalSectors > Constants.MAXSMALLDISK)
            {
                rootBlock.Options |= RootBlock.DiskOptionsEnum.MODE_SUPERINDEX;
                g.SuperMode = true;
                if (g.TotalSectors > Constants.MAXDISKSIZE1K)
                {
                    resblocksize = 2048;
                    if (g.TotalSectors > Constants.MAXDISKSIZE2K)
                    {
                        resblocksize = 4096;
                    }

                    rootBlock.DiskType = Constants.ID_PFS2_DISK;
                    //NormalErrorMsg(AFS_WARNING_EXPERIMENTAL_DISK, NULL, 1);
                }
            }

            Init.Initialize(g);
            rootBlock.Options |= RootBlock.DiskOptionsEnum.MODE_HARDDISK;

            Lru.InitLRU(g, (ushort)resblocksize);

            // Use large disk modes if block size is larger than 1024
            if (g.blocksize > resblocksize)
            {
                resblocksize = g.blocksize;
                rootBlock.DiskType = Constants.ID_PFS2_DISK;
                //NormalErrorMsg(AFS_WARNING_EXPERIMENTAL_DISK, NULL, 1);
            }

            var resCluster = resblocksize / g.blocksize;
            rootBlock.ReservedBlksize = (ushort)resblocksize;

            var numReserved = GeometryHelper.CalcNumReserved(g, resblocksize);

            rootBlock.LastReserved = (uint)(resCluster * numReserved + rootBlock.FirstReserved - 1);
            rootBlock.ReservedFree = (uint)numReserved;
            rootBlock.BlocksFree = (uint)(g.TotalSectors - resCluster * numReserved - rootBlock.FirstReserved);
            rootBlock.AlwaysFree = rootBlock.BlocksFree / 20;

            MakeReservedBitmap(rootBlock, numReserved, g); // sets reserved_free & rblkcluster too

            return rootBlock;
        }
        
        public static void MakeBitmap(globaldata g)
        {
            var alloc_data = g.glob_allocdata;
            
            /* use no_bmb as calculated by InitAllocation */
            for (uint i = 0; i < alloc_data.no_bmb; i++)
            {
                Allocation.NewBitmapBlock(i,g);
            }
        }

        public static void MakeRootDir(globaldata g)
        {
            CachedBlock blk;
            uint blocknr, anodenr;

            blocknr = Allocation.AllocReservedBlock(g);
            anodenr = anodes.AllocAnode(0, g);
            blk = Directory.MakeDirBlock(blocknr, anodenr, anodenr, 0, g);
        }        

        public static CachedBlock MakeFormatRBlkExtension(RootBlock rootBlock, globaldata g)
        {
            // if (!(rext = AllocBufmem (sizeof(struct cachedblock) + rbl->reserved_blksize, g)))
            // return FALSE;
            //memset (rext, 0, sizeof(struct cachedblock) + rbl->reserved_blksize);

            var rext = new CachedBlock
            {
                volume = g.currentvolume,
                blocknr = (uint)rootBlock.Extension,
                changeflag = true,
                blk = new rootblockextension
                {
                    id = Constants.EXTENSIONID,
                    pfs2version = (Constants.VERNUM << 16) + Constants.REVNUM,
                    RootDate = rootBlock.CreationDate,
                    fnsize = g.fnsize = 32
                }
            };
            
            g.dirty = true;
            return rext;          
        }
        
        /* makes reserved bitmap and allocates rootblockextension */
        public static void MakeReservedBitmap(RootBlock rbl, long numReserved, globaldata g)
        {
            // struct bitmapblock *bmb;
            // struct rootblock *newrootblock;
            // int *bitmap, numblocks, i, last, cluster, rescluster;

            /* calculate number of 1024 byte blocks */
            var numblocks = 1;
            for (var i = 125; i < numReserved / 32; i += 256)
            {
                numblocks++;
            }

            // convert to number of reserved blocks and allocate
            numblocks = (1024 * numblocks + rbl.ReservedBlksize - 1) / rbl.ReservedBlksize;
            rbl.ReservedFree -= (uint)numblocks;

            // convert to number of sectors
            var rescluster = rbl.ReservedBlksize / g.blocksize;
            var cluster = rbl.RblkCluster = (ushort)(rescluster * numblocks);

            /* reallocate rootblock */
            //var newrootblock = AllocBufmemR(cluster << g.blockshift, g);
            //memset (newrootblock, 0, cluster << BLOCKSHIFT);
            //memcpy (newrootblock, *rbl, BLOCKSIZE);
            //FreeBufmem(*rbl, g);
            //*rbl = newrootblock;
            //bmb = (bitmapblock_t *)(*rbl+1);		/* bitmap directly behind rootblock */
            var bmb = new BitmapBlock();

            /* init bitmapblock header */
            bmb.id = Constants.BMBLKID;
            bmb.seqnr = 0;

            /* fill bitmap */
            //bitmap = bmb->bitmap;
            bmb.bitmap = new uint[(numReserved / 32) + 1];
            for (var i = 0; i < numReserved / 32; i++)
            {
                // *bitmap++ = ~0; // ~ operator performs bitwise complement =  contain the highest possible value (signed to unsigned conversion)
                bmb.bitmap[i] = uint.MaxValue;
            }

            /* the last border */
            uint last = 0;
            for (var i = 0; i < numReserved % 32; i++)
            {
                last |= 0x80000000 >> i;
            }

            bmb.bitmap[bmb.bitmap.Length - 1] = last;

            /* allocate taken blocks + rootblock extension (de + 1)
             * The reserved area starts with the rootblock.
             * Convert numblocks from 1K blocks to actual reserved area blocks
             * */
            for (var i = 0; i < numblocks + 1; i++)
            {
                bmb.bitmap[i / 32] ^= 0x80000000 >> (i % 32);
            }

            /* rootblock extension position */
            rbl.Extension = rbl.FirstReserved + cluster;
            rbl.ReservedFree--;
        }
    }
}