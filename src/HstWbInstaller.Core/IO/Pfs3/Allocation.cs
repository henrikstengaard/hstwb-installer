namespace HstWbInstaller.Core.IO.Pfs3
{
    using System;
    using System.Threading.Tasks;
    using Blocks;

    public static class Allocation
    {
/*
 * the following routines (NewBitmapBlock & NewBitmapIndexBlock are
 * primarily (read only) used by Format
 */
        public static async Task<CachedBlock> NewBitmapBlock(uint seqnr, globaldata g)
        {
            CachedBlock blok;
            CachedBlock indexblock;
            var volume = g.currentvolume;
            var andata = g.glob_anodedata;
            var alloc_data = g.glob_allocdata;
            uint indexblnr, blocknr, indexoffset;
            uint i;
            ushort oldlock;

            /* get indexblock */
            indexblnr = seqnr / andata.indexperblock;
            indexoffset = seqnr % andata.indexperblock;
            if ((indexblock = await GetBitmapIndex((ushort)indexblnr, g)) == null)
                if ((indexblock = await NewBitmapIndexBlock((ushort)indexblnr, g)) == null)
                    return null;

            oldlock = indexblock.used;
            Cache.LOCK(indexblock, g);
            if ((blok = await Lru.AllocLRU(g)) == null || (blocknr = AllocReservedBlock(g)) == 0)
            {
                return null;
            }

            indexblock.IndexBlock.index[indexoffset] = (int)blocknr;

            blok.volume = volume;
            blok.blocknr = blocknr;
            blok.used = 0;
            var blok_blk = new BitmapBlock(g)
            {
                id = Constants.BMBLKID,
                seqnr = seqnr
            };
            blok.blk = blok_blk;
            blok.changeflag = true;

            /* fill bitmap */
            var bitmap = blok_blk.bitmap;
            for (i = 0; i < alloc_data.longsperbmb; i++)
            {
                // bitmap[i] = ~0;
                bitmap[i] = UInt32.MaxValue; //  hexadecimal 0xFFFFFFFF
            }

            Macro.MinAddHead(volume.bmblks, blok);
            await Update.MakeBlockDirty(indexblock, g);
            indexblock.used = oldlock;  	   // unlock;

            return blok;
        }
        
        public static async Task<CachedBlock> NewBitmapIndexBlock(ushort seqnr, globaldata g)
        {
            CachedBlock blok;
            var volume = g.currentvolume;

            if (seqnr > (g.SuperMode ? Constants.MAXBITMAPINDEX : Constants.MAXSMALLBITMAPINDEX) ||
                (blok = await Lru.AllocLRU(g)) == null)
            {
                return null;
            }

            if ((g.RootBlock.idx.large.bitmapindex[seqnr] = AllocReservedBlock(g)) == 0)
            {
                Lru.FreeLRU(blok, g);
                return null;
            }

            volume.rootblockchangeflag = true;

            blok.volume   = volume;
            blok.blocknr  = volume.rootblk.idx.large.bitmapindex[seqnr];
            blok.used     = 0;
            blok.blk = new indexblock(g)
            {
                id = Constants.BMIBLKID,
                seqnr = seqnr
            };
            blok.changeflag = true;
            Macro.MinAddHead(volume.bmindexblks, blok);

            return blok;
        }

        /*
         * AllocReservedBlock
         */
        public static uint AllocReservedBlock (globaldata g)
        {
            var vol = g.currentvolume;
            var alloc_data = g.glob_allocdata;
            var bitmap = alloc_data.res_bitmap.bitmap;
            //uint free = (uint)g.RootBlock.ReservedFree;
            uint blocknr;
            int i, j;

            // ENTER("AllocReservedBlock");

            /* Check if allocation possible 
             * (really necessary?)
             */
            if (g.RootBlock.ReservedFree == 0)
            {
                return 0;
            }

            j = (int)(31 - alloc_data.res_roving % 32);
            for (i = (int)(alloc_data.res_roving / 32); i < (alloc_data.numreserved + 31)/32; i++, j=31)
            {
                if (bitmap[i] != 0)
                {
                    uint field = bitmap[i];
                    for ( ;j >= 0; j--)
                    {
                        if ((field & (1 << j)) != 0)
                        {
                            blocknr = (uint)(g.RootBlock.FirstReserved + (i * 32 + (31 - j)) * vol.rescluster);
                            if (blocknr <= g.RootBlock.LastReserved)
                            {
                                bitmap[i] &= (uint)~(1 << j);
                                g.currentvolume.rootblockchangeflag = true;
                                g.dirty = true;
                                g.RootBlock.ReservedFree--;
                                alloc_data.res_roving = (uint)(32 * i + (31 - j));
                                // DB(Trace(10,"AllocReservedBlock","allocated %ld\n", blocknr));
                                return blocknr;
                            }
                        }
                    }
                }
            }

            /* end of bitmap reached. Reset roving pointer and try again 
            */
            if (alloc_data.res_roving != 0)
            {
                alloc_data.res_roving = 0;
                return AllocReservedBlock(g);
            }
            else
                return 0;

            // EXIT("AllocReservedBlock");
        }
        
        public static void FreeReservedBlock(uint blocknr, globaldata g)
        {
            /*
             * frees reserved block, or does nothing if blocknr = 0
             */
            if (blocknr != 0 && blocknr <= g.RootBlock.LastReserved)
            {
                var alloc_data = g.glob_allocdata; 
                var bitmap = alloc_data.res_bitmap.bitmap;
                var t = (blocknr - g.RootBlock.FirstReserved) / g.currentvolume.rescluster;
                bitmap[t/32] |= 0x80000000U >> (int)(t % 32);
                g.RootBlock.ReservedFree++;
                g.currentvolume.rootblockchangeflag = true;
            }
        }
        
        public static async Task<CachedBlock> GetBitmapIndex(ushort nr, globaldata g)
        {
            uint blocknr;
            CachedBlock indexblk;
            var volume = g.currentvolume;

            /* check cache */
            for (var node = Macro.HeadOf(volume.bmindexblks); node != null; node = node.Next)
            {
                indexblk = node.Value;
                if (indexblk.IndexBlock.seqnr == nr)
                {
                    Lru.MakeLRU(indexblk, g);
                    return indexblk;
                }
            }

            /* not in cache, put it in */
            if (nr > (g.SuperMode ? Constants.MAXBITMAPINDEX : Constants.MAXSMALLBITMAPINDEX) ||
                (blocknr = volume.rootblk.idx.large.bitmapindex[nr]) == 0 ||
                (indexblk = await Lru.AllocLRU(g)) == null)
            {
                return null;
            }

            // DB(Trace(10,"GetBitmapIndex", "seqnr = %ld blocknr = %lx\n", nr, blocknr));
            IBlock blk;
            if ((blk = await Disk.RawRead<BitmapBlock>(g.currentvolume.rescluster, blocknr, g)) == null)
            {
                Lru.FreeLRU(indexblk, g);
                return null;
            }
            indexblk.blk = blk;

            if (indexblk.blk.id == Constants.BMIBLKID)
            {
                indexblk.volume   = volume;
                indexblk.blocknr  = blocknr;
                indexblk.used     = 0;
                indexblk.changeflag = false;
                Macro.MinAddHead(volume.bmindexblks, indexblk);
            }
            else
            {
                // ULONG args[5];
                // args[0] = indexblk->blk.id;
                // args[1] = BMIBLKID;
                // args[2] = blocknr;
                // args[3] = nr;
                // args[4] = 0;
                Lru.FreeLRU(indexblk, g);
                // ErrorMsg (AFS_ERROR_DNV_WRONG_INDID, args, g);
                return null;
            }

            Cache.LOCK(indexblk, g);
            return indexblk;
        }
        
/*
 * Update bitmap
 */
        public static async Task UpdateFreeList(globaldata g)
        {
            CachedBlock bitmap = null;
            ushort i;
            uint longnr, blocknr, bmseqnr, newbmseqnr, bmoffset, bitnr;
            var alloc_data = g.glob_allocdata;

            /* sort the free list */
            // not done right now

            /* free all blocks in list */
            bmseqnr = UInt32.MaxValue;
            for (i = 0; i < alloc_data.tobefreed_index; i++)
            {
                for ( blocknr = alloc_data.tobefreed[i][Constants.TBF_BLOCKNR];
                     blocknr < alloc_data.tobefreed[i][Constants.TBF_SIZE] + alloc_data.tobefreed[i][Constants.TBF_BLOCKNR];
                     blocknr++ )
                {
                    /* now free block blocknr */
                    bitnr = blocknr - alloc_data.bitmapstart;
                    longnr = bitnr / 32;
                    newbmseqnr = longnr / alloc_data.longsperbmb;
                    bmoffset = longnr % alloc_data.longsperbmb;
                    if(newbmseqnr != bmseqnr)
                    {
                        bmseqnr = newbmseqnr;
                        bitmap = await GetBitmapBlock(bmseqnr, g);
                    }
                    bitmap.BitmapBlock.bitmap[bmoffset] |= (uint)(1<<(int)(31-(bitnr % 32)));
                    await Update.MakeBlockDirty(bitmap, g);
                }

                alloc_data.clean_blocksfree += alloc_data.tobefreed[i][Constants.TBF_SIZE];
            }

            /* update global data */
            /* alloc_data.alloc_available should already be equal blocksfree - alwaysfree */
            alloc_data.tobefreed_index = 0;
            alloc_data.tbf_resneed = 0;
            g.RootBlock.BlocksFree = alloc_data.clean_blocksfree;
            g.currentvolume.rootblockchangeflag = true;
        }
        
/* this routine is analogous GetAnodeBlock()
 * GetBitmapIndex is analogous GetIndexBlock()
 */
        public static async Task<CachedBlock> GetBitmapBlock(uint seqnr, globaldata g)
        {
            uint blocknr, temp;
            CachedBlock bmb;
            CachedBlock indexblock;
            var volume = g.currentvolume;
            var andata = g.glob_anodedata;

            /* check cache */
            for (var node = Macro.HeadOf(volume.bmblks); node != null; node = node.Next)
            {
                bmb = node.Value;
                if (bmb.BitmapBlock.seqnr == seqnr)
                {
                    Lru.MakeLRU(bmb, g);
                    return bmb;
                }
            }

            /* not in cache, put it in */
            /* get the indexblock */
            temp = Init.divide(seqnr, andata.indexperblock);
            if ((indexblock = await GetBitmapIndex((ushort)temp /* & 0xffff */, g)) == null)
                return null;

            /* get blocknr */
            if ((blocknr = (uint)indexblock.IndexBlock.index[temp>>16]) == 0 ||
                (bmb = await Lru.AllocLRU(g)) == null)
                return null;

            // DB(Trace(10,"GetBitmapBlock", "seqnr = %ld blocknr = %lx\n", seqnr, blocknr));

            /* read it */
            var blk = await Disk.RawRead<BitmapBlock>(g.currentvolume.rescluster, blocknr, g);
            if (blk == null)
            {
                Lru.FreeLRU(bmb, g);
                return null;
            }

            /* check it */
            if (bmb.blk.id != Constants.BMBLKID)
            {
                // ULONG args[2];
                // args[0] = bmb->blk.id;
                // args[1] = blocknr;
                Lru.FreeLRU(bmb, g);
                // ErrorMsg (AFS_ERROR_DNV_WRONG_BMID, args, g);
                return null;
            }
	
            /* initialize it */
            bmb.volume = volume;
            bmb.blocknr = blocknr;
            bmb.used = 0;
            bmb.changeflag = false;
            Macro.MinAddHead(volume.bmblks, bmb);

            return bmb;
        }
    }
}