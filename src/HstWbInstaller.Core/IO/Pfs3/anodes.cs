namespace HstWbInstaller.Core.IO.Pfs3
{
    using System;
    using Blocks;

    public class anodes
    {
        /**********************************************************************/
        /* indexblocks                                                        */
        /**********************************************************************/

        /*
         * get indexblock nr
         * returns NULL if failure
         */
        public static CachedBlock GetIndexBlock(ushort nr, globaldata g)
        {
            uint blocknr, temp;
            CachedBlock indexblk;
            CachedBlock superblk;
            var volume = g.currentvolume;
            var andata = g.glob_anodedata;

            /* check cache (can be empty) */
            for (var node = volume.indexblks.First; node != null && node.Next != null; node = node.Next)
            {
                indexblk = node.Value;
                if (indexblk.IndexBlock.seqnr == nr)
                {
                    Lru.MakeLRU(indexblk, g);
                    return node.Value;
                }
            }

            /* not in cache, put it in
	 * first, get blocknr
	 */
            if (g.SuperMode)
            {
                /* temp is chopped by auto cast */
                temp = Init.divide(nr, andata.indexperblock);
                if ((superblk = GetSuperBlock((ushort)temp, g)) == null)
                {
                    //DBERR(ErrorTrace(5, "GetIndexBlock", "ERR: superblock not found. %lu %lu %08lx\n", nr, andata.indexperblock, temp));
                    return null;
                }

                if ((blocknr = (uint)superblk.IndexBlock.index[temp >> 16]) == 0)
                {
                    //DBERR(ErrorTrace(5, "GetIndexBlock", "ERR: super zero. %lu %lu %08lx\n", nr, andata.indexperblock, temp));
                    return null;
                }
            }
            else
            {
                if (nr > Constants.MAXSMALLINDEXNR || (blocknr = volume.rootblk.idx.small.indexblocks[nr]) == 0)
                    return null;
            }

            /* allocate space from cache */
            if ((indexblk = Lru.AllocLRU(g)) == null)
            {
                //DBERR(ErrorTrace(5, "GetIndexBlock", "ERR: AllocLRU. %lu %lu %08lx %lu\n", nr, andata.indexperblock, temp, blocknr));
                return null;
            }

            //DBERR(ErrorTrace(10,"GetIndexBlock","seqnr = %lu blocknr = %lu\n", nr, blocknr));

            // if (RawRead ((UBYTE*)&indexblk->blk, RESCLUSTER, blocknr, g) != 0) {
            //     FreeLRU ((struct cachedblock *)indexblk);
            //     return NULL;
            // }
            if (!Disk.RawRead(g.currentvolume.rescluster, blocknr, g, out var blk))
            {
                //     FreeLRU ((struct cachedblock *)indexblk);
                return null;
            }

            var indexblk_blk = indexblk.IndexBlock;
            if (indexblk_blk.id == Constants.IBLKID)
            {
                indexblk.volume = volume;
                indexblk.blocknr = blocknr;
                indexblk.used = 0;
                indexblk.changeflag = false;
                volume.indexblks.AddFirst(indexblk);
            }
            else
            {
                // ULONG args[5];
                // args[0] = indexblk->blk.id;
                // args[1] = IBLKID;
                // args[2] = blocknr;
                // args[3] = nr;
                // args[4] = andata.indexperblock;
                // FreeLRU ((struct cachedblock *)indexblk);
                // ErrorMsg (AFS_ERROR_DNV_WRONG_INDID, args, g);
                return null;
            }

            return indexblk;
        }

        public static CachedBlock GetSuperBlock(ushort nr, globaldata g)
        {
            uint blocknr;
            CachedBlock superblk;
            var volume = g.currentvolume;

            // DBERR(blocknr = 0xffdddddd);

            /* check supermode */
            if (!g.SuperMode)
            {
                // DBERR(ErrorTrace(1, "GetSuperBlock", "ERR: Illegally entered\n"));
                return null;
            }

            /* check cache (can be empty) */
            for (var node = volume.superblks.First; node != null && node.Next != null; node = node.Next)
            {
                superblk = node.Value;
                var superblk_blk = superblk.IndexBlock;
                if (superblk_blk.seqnr == nr)
                {
                    Lru.MakeLRU(superblk, g);
                    return node.Value;
                }
            }

            /* not in cache, put it in
             * first, get blocknr
             */
            if (nr > Constants.MAXSUPER || (blocknr = volume.rblkextension.rblkextension.superindex[nr]) == 0)
            {
                //DBERR(ErrorTrace(1, "GetSuperBlock", "ERR: out of bounds. %lu %lu\n", nr, blocknr));
                return null;
            }

            /* allocate space from cache */
            // if (!(superblk = (struct cindexblock *)AllocLRU(g))) {
            //     DBERR(ErrorTrace(1, "GetSuperBlock", "ERR: AllocLRU error. %lu %lu\n", nr, blocknr));
            //     return NULL;
            // }
            if ((superblk = Lru.AllocLRU(g)) == null)
            {
                return null;
            }

            // DBERR(ErrorTrace(10,"GetSuperBlock","seqnr = %lu blocknr = %lu\n", nr, blocknr));

            // if (RawRead ((UBYTE*)&superblk->blk, RESCLUSTER, blocknr, g) != 0) {
            //     DBERR(ErrorTrace(1, "GetSuperBlock", "ERR: read error. %lu %lu\n", nr, blocknr));
            //     FreeLRU ((struct cachedblock *)superblk);
            //     return NULL;
            // }
            //var superblk = IndexBlockReader.Read(g.currentvolume.rescluster, blocknr);
            if (!Disk.RawRead(g.currentvolume.rescluster, blocknr, g, out var blk))
            {
                return null;
            }

            superblk.blk = blk;

            if (superblk.blk.id == Constants.SBLKID)
            {
                superblk.volume = volume;
                superblk.blocknr = blocknr;
                superblk.used = 0;
                superblk.changeflag = false;
                Macro.MinAddHead(volume.superblks, superblk);
            }
            else
            {
                // ULONG args[5];
                // args[0] = superblk->blk.id;
                // args[1] = SBLKID;
                // args[2] = blocknr;
                // args[3] = nr;
                // args[4] = 0;
                // FreeLRU ((struct cachedblock *)superblk);
                // ErrorMsg (AFS_ERROR_DNV_WRONG_INDID, args, g);
                return null;
            }

            return superblk;
        }
        
        public static CachedBlock NewSuperBlock(ushort seqnr, globaldata g)
        {
            CachedBlock blok;
            var volume = g.currentvolume;

            // DBERR(blok = NULL;)

            if ((seqnr > Constants.MAXSUPER) || (blok = Lru.AllocLRU(g)) == null)
            {
                // DBERR(ErrorTrace(1, "NewSuperBlock", "ERR: out of bounds or LRU error. %lu %p\n", seqnr, blok));
                return null;
            }

            if (volume.rblkextension.rblkextension.superindex[seqnr] != Allocation.AllocReservedBlock(g))
            {
                // DBERR(ErrorTrace(1, "NewSuperBlock", "ERR: AllocReservedBlock. %lu %p\n", seqnr, blok));
                Lru.FreeLRU(blok, g);
                return null;
            }
 
            // DBERR(ErrorTrace(10,"NewSuperBlock", "seqnr = %lu block = %lu\n", seqnr, volume->rblkextension->blk.superindex[seqnr]));

            volume.rblkextension.changeflag = true;

            blok.volume     = volume;
            blok.blocknr    = volume.rblkextension.rblkextension.superindex[seqnr];
            blok.used       = 0;
            var blok_cblk = blok.IndexBlock;
            blok_cblk.id     = Constants.SBLKID;
            blok_cblk.seqnr  = seqnr;
            blok.changeflag = true;
            Macro.MinAddHead(volume.superblks, blok);

            return blok;
        }

        /* Find out how large the anblkbitmap must be, allocate it and
 * initialise it. Free any preexisting anblkbitmap
 *
 * The anode bitmap is used for allocating anodes. It has the
 * following properties:
 * - It is  maintained in memory only (not on disk). 
 * - Intialization is lazy: all anodes are marked as available
 * - When allocation anodes (see AllocAnode), this bitmap is used
 *   to find available anodes. It then checks with the actual
 *   anode (which should be 0,0,0 if available). If it isn't really
 *   available, the anodebitmap is updated, otherwise the anode is
 *   taken.
 */
        public static void MakeAnodeBitmap(bool formatting, globaldata g)
        {
            CachedBlock iblk;
            CachedBlock sblk;
            int i, j, s = 0;
            uint size;
            var andata = g.glob_anodedata;

            // if (andata.anblkbitmap)
            //     FreeMemP (andata.anblkbitmap, g);            

            /* count number of anodeblocks and allocate bitmap */
            if (formatting)
            {
                i = 0;
                s = 0;
                j = 1;
            }
            else
            {
                if (g.SuperMode)
                {
                    for (s = Constants.MAXSUPER; s >= 0 && g.currentvolume.rblkextension.rblkextension.superindex[s] == 0; s--)
                    {
                    }

                    if (s < 0)
                    {
                        //goto error;					
                        throw new Exception("AFS_ERROR_ANODE_ERROR");
                    }

                    sblk = GetSuperBlock((ushort)s, g);

                    //DBERR(if (!sblk) ErrorTrace(1, "MakeAnodeBitmap", "ERR: GetSuperBlock returned NULL!. %ld\n", s));

                    var sblk_blk = sblk.IndexBlock;
                    for (i = andata.indexperblock - 1; i >= 0 && sblk_blk.index[i] == 0; i--)
                    {
                    }
                }
                else
                {
                    for (s = 0, i = Constants.MAXSMALLINDEXNR; i >= 0 && g.RootBlock.idx.small.indexblocks[i] == 0; i--)
                    {
                    }
                }

                if (i < 0)
                {
                    // goto error;
                    throw new Exception("AFS_ERROR_ANODE_ERROR");
                }

                iblk = GetIndexBlock((ushort)(s * andata.indexperblock + i), g);

                //DBERR(if (!iblk) ErrorTrace(1, "MakeAnodeBitmap", "ERR: GetIndexBlock returned NULL!. %ld %ld\n", s, i));

                var iblk_blk = iblk.IndexBlock;
                for (j = andata.indexperblock - 1; j >= 0 && iblk_blk.index[j] == 0; j--)
                {
                }
            }

            if (g.SuperMode)
            {
                andata.maxanseqnr =
                    (uint)(s * andata.indexperblock * andata.indexperblock + i * andata.indexperblock + j);
                size = (uint)(((s * andata.indexperblock + i + 1) * andata.indexperblock + 7) / 8);
            }
            else
            {
                andata.maxanseqnr = (uint)(i * andata.indexperblock + j);
                size = (uint)(((i + 1) * andata.indexperblock + 7) / 8);
            }

            andata.anblkbitmapsize = (uint)((size + 3) & ~3);
            //andata.anblkbitmap = AllocMemP(andata.anblkbitmapsize, g);
            //#define AllocMemP(size,g) ((g->allocmemp)(size,g))
            andata.anblkbitmap = new uint[andata.anblkbitmapsize];

            for (i = 0; i < andata.anblkbitmapsize / 4; i++)
            {
                andata.anblkbitmap[i] = 0xffffffff; /* all available */
            }
        }

/* saves and anode..
*/
        public static void SaveAnode(canode anode, uint anodenr, globaldata g)
        {
            // anode anode
            uint temp;
            ushort seqnr, anodeoffset;
            // struct canodeblock* ablock;
            var andata = g.glob_anodedata;
            
            if (g.anodesplitmode)
            {
                // anodenr_t* split = (anodenr_t*)&anodenr;
                var split = Macro.SplitAnodenr(anodenr);
                seqnr = split.seqnr;
                anodeoffset = split.offset;
            }
            else
            {
                temp = Init.divide(anodenr, andata.anodesperblock);
                seqnr = (ushort)temp; // 1e block = 0
                anodeoffset = (ushort)(temp >> 16);
            }

            anode.nr = anodenr;

            /* Save Anode */
            var ablock = Macro.GetAnodeBlock(seqnr, g);
            if (ablock != null)
            {
                var anode_blk = ablock.ANodeBlock;
                anode_blk.nodes[anodeoffset].clustersize = anode.clustersize;
                anode_blk.nodes[anodeoffset].blocknr = anode.blocknr;
                anode_blk.nodes[anodeoffset].next = anode.next;
                Update.MakeBlockDirty(ablock, g);
            }
            else
            {
                //DBERR(ErrorTrace(5, "SaveAnode", "ERR: anode = 0x%lx\n", anodenr));
                // ErrorMsg (AFS_ERROR_DNV_ALLOC_BLOCK, NULL);
                throw new Exception("AFS_ERROR_DNV_ALLOC_BLOCK");
            }
        }

/* allocates an anode and marks it as reserved
 * connect is anodenr to connect to (0 = no connection)
 */
        public static uint AllocAnode(uint connect, globaldata g)
        {
            int i, j, k = 0;
            CachedBlock ablock = null;
            anode[] anodes = null;
            bool found = false;
            uint seqnr = 0, field;

            var andata = g.glob_anodedata;

            if (connect != 0 && g.anodesplitmode)
            {
                /* try to place new anode in same block */
                ablock = Init.big_GetAnodeBlock((ushort)(seqnr = connect >> 16), g);
                if (ablock != null)
                {
                    anodes = ablock.ANodeBlock.nodes;
                    for (k = andata.anodesperblock - 1; k > -1 && !found; k--)
                        found = (anodes[k].clustersize == 0 &&
                                 anodes[k].blocknr == 0 &&
                                 anodes[k].next == 0);
                }
            }
            else
            {
                for (i = andata.curranseqnr / 32; i < andata.maxanseqnr / 32 + 1; i++)
                {
                    // DBERR(if (i >= andata.anblkbitmapsize / 4 || i < 0)
                    // 	ErrorTrace(5, "AllocAnode","ERR: anblkbitmap out of bounds %lu >= %lu\n", i, andata.anblkbitmapsize / 4));

                    field = andata.anblkbitmap[i];
                    if (field != null)
                    {
                        for (j = 31; j >= 0; j--)
                        {
                            if ((field & (1 << j)) != 0)
                            {
                                seqnr = (uint)(i * 32 + 31 - j);
                                ablock = Init.big_GetAnodeBlock((ushort)seqnr, g);
                                if (ablock != null)
                                {
                                    anodes = ablock.ANodeBlock.nodes;
                                    for (k = 0; k < andata.reserved && !found; k++)
                                        found = (anodes[k].clustersize == 0 &&
                                                 anodes[k].blocknr == 0 &&
                                                 anodes[k].next == 0);

                                    if (found)
                                        goto found_it;
                                    else
                                        /* mark anodeblock as full */
                                        andata.anblkbitmap[i] &= (uint)(~(1 << j));
                                }
                                /* anodeblock does not exist */
                                else goto found_it;
                            }
                        }
                    }
                }

                seqnr = andata.maxanseqnr + 1;
            }

            found_it:

            if (!found)
            {
                /* give up connect mode and try again */
                if (connect != 0)
                    return AllocAnode(0, g);

                /* start over if not started from start of list;
                 * else make new block
                 */
                if (andata.curranseqnr != 0)
                {
                    andata.curranseqnr = 0;
                    return AllocAnode(0, g);
                }
                else
                {
                    if ((ablock = big_NewAnodeBlock((ushort)seqnr, g)) == null)
                        return 0;
                    anodes = ablock.ANodeBlock.nodes;
                    k = 0;
                }
            }
            else
            {
                if (connect != 0)
                    k++;
                else
                    k--;
            }

            anodes[k].clustersize = 0;
            anodes[k].blocknr = 0xffffffff;
            anodes[k].next = 0;

            Update.MakeBlockDirty(ablock, g);
            andata.curranseqnr = (ushort)seqnr;

            if (g.anodesplitmode)
                return (uint)(seqnr << 16 | k);
            else
                return (uint)(seqnr * andata.anodesperblock + k);
        }
        
        public static CachedBlock big_NewAnodeBlock(ushort seqnr, globaldata g)
        {
            /* MODE_BIG has difference between anodeblocks and fnodeblocks*/

            CachedBlock blok;
            var volume = g.currentvolume;
            var andata = g.glob_anodedata;
            CachedBlock indexblock;
            uint indexblnr;
            int blocknr;
            ushort indexoffset, oldlock;

            /* get indexblock */
            indexblnr = (uint)(seqnr / andata.indexperblock);
            indexoffset = (ushort)(seqnr % andata.indexperblock);
            if ((indexblock = GetIndexBlock((ushort)indexblnr, g)) == null) {
                if ((indexblock = NewIndexBlock((ushort)indexblnr, g)) == null) {
                    // DBERR(ErrorTrace(10,"big_NewAnodeBlock","ERR: NewIndexBlock %lu %lu %lu %lu\n", seqnr, indexblnr, indexoffset, andata.indexperblock));
                    return null;
                }
            }

            oldlock = indexblock.used;
            Cache.LOCK(indexblock, g);
            if ((blok = Lru.AllocLRU(g)) == null || (blocknr = (int)Allocation.AllocReservedBlock(g)) == 0 ) {
                // DBERR(ErrorTrace(10,"big_NewAnodeBlock","ERR: AllocLRU/AllocReservedBlock %lu %lu %lu\n", seqnr, indexblnr, indexoffset));
                indexblock.used = oldlock;         // unlock block
                return null;
            }

            // DBERR(ErrorTrace(10,"big_NewAnodeBlock", "seqnr = %lu block = %lu\n", seqnr, blocknr));

            indexblock.IndexBlock.index[indexoffset] = blocknr;

            blok.volume     = volume;
            blok.blocknr    = (uint)blocknr;
            blok.used       = 0;
            var blok_blk = blok.IndexBlock;
            blok_blk.id     = Constants.ABLKID;
            blok_blk.seqnr  = seqnr;
            blok.changeflag = true;
            Init.Hash(blok, volume.anblks, Constants.HASHM_ANODE);
            Update.MakeBlockDirty(indexblock, g);
            indexblock.used = oldlock;         // unlock block

            anodes.ReallocAnodeBitmap(seqnr, g);
            return blok;
        }
        
        public static CachedBlock NewIndexBlock(ushort seqnr, globaldata g)
        {
            CachedBlock blok;
            CachedBlock superblok = null;
            var volume = g.currentvolume;
            var andata = g.glob_anodedata;
            uint superblnr = 0;
            int blocknr;
            ushort superoffset = 0;

            if (g.SuperMode)
            {
                superblnr = (uint)(seqnr / andata.indexperblock);
                superoffset = (ushort)(seqnr % andata.indexperblock);
                if ((superblok = GetSuperBlock((ushort)superblnr, g)) == null)
                {
                    if ((superblok = NewSuperBlock((ushort)superblnr, g)) == null)
                    {
                        // DBERR(ErrorTrace(1, "NewIndexBlock", "ERR: Super not found. %lu %lu %lu %lu\n", seqnr, andata.indexperblock, superblnr, superoffset));
                        return null;
                    }
                    // else
                    // {
                    //     DBERR(ErrorTrace(1, "NewIndexBlock", "OK. %lu %lu %lu %lu\n", seqnr, andata.indexperblock, superblnr, superoffset));		
                    // }
                }

                Cache.LOCK(superblok, g);
            }
            else if (seqnr > Constants.MAXSMALLINDEXNR) {
                return null;
            }

            if ((blok = Lru.AllocLRU(g)) == null || (blocknr = (int)Allocation.AllocReservedBlock(g)) == 0)
            {
                // DBERR(ErrorTrace(1, "NewIndexBlock", "ERR: AllocLRU/AllocReservedBlock. %lu %lu %lu %lu\n", seqnr, blocknr, superblnr, superoffset));
                if (blok != null)
                    Lru.FreeLRU(blok, g);
                return null;
            }

            // DBERR(ErrorTrace(10,"NewIndexBlock", "seqnr = %lu block = %lu\n", seqnr, blocknr));

            if (g.SuperMode) {
                superblok.IndexBlock.index[superoffset] = blocknr;
                Update.MakeBlockDirty(superblok, g);
            } else {
                volume.rootblk.idx.small.indexblocks[seqnr] = (uint)blocknr;
                volume.rootblockchangeflag = true;
            }

            blok.volume     = volume;
            blok.blocknr    = (uint)blocknr;
            blok.used       = 0;
            var blok_blk = blok.IndexBlock;
            blok_blk.id     = Constants.IBLKID;
            blok_blk.seqnr  = seqnr;
            blok.changeflag = true;
            Macro.MinAddHead(volume.indexblks, blok);

            return blok;
        }
        
/* test if new anodeseqnr causes change in anblkbitmap */
        public static void ReallocAnodeBitmap(uint newseqnr, globaldata g)
        {
            uint newsize;
            int t;
            var andata = g.glob_anodedata;

            if (newseqnr > andata.maxanseqnr)
            {
                andata.maxanseqnr = newseqnr;
                newsize = ((newseqnr/andata.indexperblock + 1) * andata.indexperblock + 7) / 8;
                if (newsize > andata.anblkbitmapsize)
                {
                    newsize = (uint)((newsize + 3) & ~3);   /* longwords */
                    // newbitmap = AllocMemP (newsize, g);
                    var newbitmap = new uint[newsize];
                    for (t = 0; t < newsize / 4; t++)
                        newbitmap[t] = 0xffffffff;
                    //memcpy (newbitmap, andata.anblkbitmap, andata.anblkbitmapsize);
                    //FreeMemP (andata.anblkbitmap, g);
                    andata.anblkbitmap = newbitmap;
                    andata.anblkbitmapsize = newsize;
                }
            }
        }
    }
}