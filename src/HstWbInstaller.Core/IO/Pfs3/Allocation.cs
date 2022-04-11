namespace HstWbInstaller.Core.IO.Pfs3
{
    using System;
    using Blocks;

    public static class Allocation
    {
/*
 * the following routines (NewBitmapBlock & NewBitmapIndexBlock are
 * primarily (read only) used by Format
 */
        public static CachedBlock NewBitmapBlock(uint seqnr, globaldata g)
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
            if ((indexblock = GetBitmapIndex((ushort)indexblnr, g)) == null)
                if ((indexblock = NewBitmapIndexBlock((ushort)indexblnr, g)) == null)
                    return null;

            oldlock = indexblock.used;
            Cache.LOCK(indexblock, g);
            if ((blok = Lru.AllocLRU(g)) == null || (blocknr = AllocReservedBlock(g)) == 0)
            {
                return null;
            }

            indexblock.IndexBlock.index[indexoffset] = (int)blocknr;

            blok.volume = volume;
            blok.blocknr = blocknr;
            blok.used = 0;
            var blok_blk = blok.BitmapBlock;
            blok_blk.id = Constants.BMBLKID;
            blok_blk.seqnr = seqnr;
            blok.changeflag = true;

            /* fill bitmap */
            var bitmap = blok_blk.bitmap;
            for (i = 0; i < alloc_data.longsperbmb; i++)
            {
                // bitmap[i] = ~0;
                bitmap[i] = UInt32.MaxValue; //  hexadecimal 0xFFFFFFFF
            }

            Macro.MinAddHead(volume.bmblks, blok);
            Update.MakeBlockDirty(indexblock, g);
            indexblock.used = oldlock;  	   // unlock;

            return blok;
        }
        
        public static CachedBlock NewBitmapIndexBlock(ushort seqnr, globaldata g)
        {
            CachedBlock blok;
            var volume = g.currentvolume;

            if (seqnr > (g.SuperMode ? Constants.MAXBITMAPINDEX : Constants.MAXSMALLBITMAPINDEX) ||
                (blok = Lru.AllocLRU(g)) == null)
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
            var blok_blk = blok.IndexBlock;
            blok_blk.id   = Constants.BMIBLKID;
            blok_blk.seqnr  = seqnr;
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
            uint i, j;

            // ENTER("AllocReservedBlock");

            /* Check if allocation possible 
             * (really necessary?)
             */
            if (g.RootBlock.ReservedFree == 0)
            {
                return 0;
            }

            j = 31 - alloc_data.res_roving % 32;
            for (i = alloc_data.res_roving / 32; i < ((alloc_data.numreserved + 31)/32); i++, j=31)
            {
                if (bitmap[i] != 0)
                {
                    uint field = bitmap[i];
                    for ( ;j >= 0; j--)
                    {
                        if ((field & (1 << (int)j)) != 0)
                        {
                            blocknr = (uint)(g.RootBlock.FirstReserved + (i*32+(31-j))* vol.rescluster);
                            if (blocknr <= g.RootBlock.LastReserved) 
                            {
                                bitmap[i] &= (uint)~(1 << (int)j);
                                g.currentvolume.rootblockchangeflag = true;
                                g.dirty = true;
                                g.RootBlock.ReservedFree--;
                                alloc_data.res_roving = 32 * i + (31 - j);
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
        
        public static CachedBlock GetBitmapIndex(ushort nr, globaldata g)
        {
            uint blocknr;
            CachedBlock indexblk;
            var volume = g.currentvolume;

            /* check cache */
            for (var node = Macro.HeadOf(volume.bmindexblks); node != null && node.Next != null; node = node.Next)
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
                (indexblk = Lru.AllocLRU(g)) == null)
            {
                return null;
            }

            // DB(Trace(10,"GetBitmapIndex", "seqnr = %ld blocknr = %lx\n", nr, blocknr));
            if (!Disk.RawRead(g.currentvolume.rescluster, blocknr, g, out var blk)) {
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
    }
}