namespace HstWbInstaller.Core.IO.Pfs3
{
    using System;
    using System.Collections.Generic;
    using System.Linq;
    using System.Threading.Tasks;
    using Blocks;

    public static class Lru
    {
        private const int MIN_BUFFERS = 10;
        private const int MAX_BUFFERS = 600;
        private const int NEW_LRU_ENTRIES = 5;

/* Allocate LRU queue
*/
        public static void InitLRU(globaldata g, ushort reservedBlksize)
        {
            if (g.glob_lrudata.LRUarray != null && g.glob_lrudata.reservedBlksize == reservedBlksize)
            {
                return;
            }

            g.glob_lrudata.reservedBlksize = reservedBlksize;

            // NewList((struct List<> *)&g->glob_lrudata.LRUqueue);
            // NewList((struct List *)&g->glob_lrudata.LRUpool);
            g.glob_lrudata.LRUqueue = new LinkedList<LruCachedBlock>();
            g.glob_lrudata.LRUpool = new LinkedList<LruCachedBlock>();

            var i = g.NumBuffers;

            /* sanity checks. If HDToolbox default of 30, then 150,
             * otherwise round in range 70 -- 600
             */
            if (i == 30) i = 150;
            if (i < MIN_BUFFERS) i = MIN_BUFFERS;
            if (i > MAX_BUFFERS) i = MAX_BUFFERS;
            g.NumBuffers = g.glob_lrudata.poolsize = i;
            g.uip = false;
            g.locknr = 1;

            g.glob_lrudata.LRUarray = Enumerable.Range(1, (int)g.glob_lrudata.poolsize)
                    .Select(_ => new LruCachedBlock(new CachedBlock(g))).ToArray();
        }

        public static CachedBlock CheckCache(LinkedList<CachedBlock>[] list, ushort mask, uint blocknr, globaldata g)
        {
            for (var block = Macro.HeadOf(list[(blocknr / 2) & mask]);
                 block != null;
                 block = block.Next)
            {
                if (block.Value.blocknr == blocknr)
                {
                    MakeLRU(block.Value, g);
                    return block.Value;
                }
            }

            return default;
        }

        public static void MakeLRU(CachedBlock blk, globaldata g)
        {
            // MinRemove(LRU_CHAIN(blk));
            Macro.MinRemove(blk, g);

            // MinAddHead(g.glob_lrudata.LRUqueue, LRU_CHAIN(blk));
            Macro.MinAddHead(g.glob_lrudata.LRUqueue, new LruCachedBlock(blk));
        }

        public static void FreeLRU(CachedBlock blk, globaldata g)
        {
            //MinRemove(LRU_CHAIN(blk));                          \
            //memset(blk, 0, SIZEOF_CACHEDBLOCK);              \
            Macro.MinRemove(blk, g);
            ClearBlock(blk);

            //MinAddHead(&g->glob_lrudata.LRUpool, LRU_CHAIN(blk));            \
            Macro.MinAddHead(g.glob_lrudata.LRUpool, new LruCachedBlock(blk));
        }

/* Allocate a block from the LRU chain and make
** it current LRU.
** Returns NULL if none available
*/
        public static async Task<CachedBlock> AllocLRU(globaldata g)
        {
            // struct lru_cachedblock* lrunode;
            // struct lru_cachedblock** nlru;
            // ULONG error;
            int retries = 0;
            int j;

            //ENTER("AllocLRU");

            if (g.glob_lrudata.LRUarray == null)
                return default;

            /* Use free block from pool or flush lru unused
            ** block (there MUST be one!)
            */
            LinkedListNode<LruCachedBlock> lrunode;
            retry:
            if (g.glob_lrudata.LRUpool.Count == 0)
            {
                for (lrunode = g.glob_lrudata.LRUqueue.Last; lrunode != null; lrunode = lrunode.Previous)
                    // for (lrunode = (struct lru_cachedblock *)g->glob_lrudata.LRUqueue.mlh_TailPred;
                    // lrunode->prev;
                    // lrunode = lrunode->prev)
                {
                    /* skip locked blocks */
                    if (Cache.ISLOCKED(lrunode.Value.cblk, g))
                        continue;

                    if (lrunode.Value.cblk.changeflag)
                    {
                        //DB(Trace(1, "AllocLRU", "ResToBeFreed %lx\n", &lrunode->cblk));
                        ResToBeFreed(lrunode.Value.cblk.oldblocknr, g);
                        Update.UpdateDatestamp(lrunode.Value.cblk, g);
                        if (!(await Disk.RawWrite(g.stream, lrunode.Value.cblk.blk, g.currentvolume.rescluster,
                                lrunode.Value.cblk.blocknr, g)))
                        {
                            // ULONG args[2];
                            // args[0] = lrunode->cblk.blocknr;
                            // args[1] = error;
                            //ErrorMsg(AFS_ERROR_LRU_UPDATE_FAIL, args, g);
                            throw new Exception("AFS_ERROR_LRU_UPDATE_FAIL");
                        }
                    }

                    FlushBlock(lrunode.Value.cblk, g);
                    goto ready;
                }
            }
            else
            {
                lrunode = Macro.HeadOf(g.glob_lrudata.LRUpool);
                goto ready;
            }

            /* Attempt to allocate new entries */
            //nlru = AllocVec(sizeof(struct lru_cachedblock *) *(g->glob_lrudata.poolsize + NEW_LRU_ENTRIES), MEMF_CLEAR);
            var nlru = new LruCachedBlock[g.glob_lrudata.poolsize + NEW_LRU_ENTRIES];
            for (j = 0; j < NEW_LRU_ENTRIES; j++)
            {
                if (nlru == null)
                    break;
                // nlru[j + g->glob_lrudata.poolsize] = AllocVec((sizeof(struct lru_cachedblock) +SIZEOF_RESBLOCK)
                //     , g->dosenvec->de_BufMemType | MEMF_CLEAR);
                nlru[j + g.glob_lrudata.poolsize] = new LruCachedBlock(new CachedBlock(g));

                if (nlru[j + g.glob_lrudata.poolsize] == null)
                {
                    while (j >= 0)
                    {
                        // FreeVec(nlru[j + g->glob_lrudata.poolsize]);
                        j--;
                    }

                    // FreeVec(nlru);
                    nlru = null;
                }
            }

            if (nlru == null)
            {
            //     /* No suitable block found -> we are in trouble */
            //     //NormalErrorMsg(AFS_ERROR_OUT_OF_BUFFERS, NULL, 1);
                retries++;
                if (retries > 3)
                    return null;
                
                goto retry;
            }

            // CopyMem(g->glob_lrudata.LRUarray, nlru, sizeof(struct lru_cachedblock *) *g->glob_lrudata.poolsize);
            // FreeVec(g->glob_lrudata.LRUarray);
            for (var i = 0; i < g.glob_lrudata.poolsize; i++)
            {
                nlru[i] = g.glob_lrudata.LRUarray[i];
            }
            g.glob_lrudata.LRUarray = nlru;
            for (j = 0; j < NEW_LRU_ENTRIES; j++, g.glob_lrudata.poolsize++)
            {
                //MinAddHead(&g->glob_lrudata.LRUpool, g.glob_lrudata.LRUarray[g.glob_lrudata.poolsize]);
                Macro.MinAddHead(g.glob_lrudata.LRUpool,
                    g.glob_lrudata.LRUarray[(int)g.glob_lrudata.poolsize]);
            }

            g.NumBuffers = g.glob_lrudata.poolsize;
            goto retry;

            ready:

            // MinRemove(lrunode);
            // MinAddHead(&g->glob_lrudata.LRUqueue, lrunode);
            Macro.MinRemove(lrunode.Value, g);
            Macro.MinRemoveX(lrunode.Value.cblk, g);
            Macro.MinAddHead(g.glob_lrudata.LRUqueue, lrunode.Value);

            // DB(Trace(1, "AllocLRU", "Allocated block %lx\n", &lrunode->cblk));

            //  LOCK(&lrunode->cblk);
            Cache.LOCK(lrunode.Value.cblk, g);
            return lrunode.Value.cblk;
        }

/* Adds a block to the ReservedToBeFreedCache
 */
        public static void ResToBeFreed(uint blocknr, globaldata g)
        {
            var alloc_data = g.glob_allocdata;

            /* bug 00116, 13 June 1998 */
            if (blocknr != 0)
            {
                /* check if cache has space left */
                if (alloc_data.rtbf_index < alloc_data.rtbf_size)
                {
                    alloc_data.reservedtobefreed[alloc_data.rtbf_index++] = blocknr;
                }
                else
                {
                    /* reallocate cache */
                    uint newsize = alloc_data.rtbf_size != 0 ? alloc_data.rtbf_size * 2 : Constants.RTBF_CACHE_SIZE;
                    // uint *newbuffer = AllocMem(sizeof(*newbuffer) * newsize, MEMF_ANY);
                    var newbuffer = new uint[newsize];
                    // if (newbuffer)
                    // {
                    if (alloc_data.reservedtobefreed != null)
                    {
                        // CopyMem(alloc_data.reservedtobefreed, newbuffer, sizeof(*newbuffer) * alloc_data.rtbf_index);
                        // FreeMem(alloc_data.reservedtobefreed, sizeof(*newbuffer) * alloc_data.rtbf_size);
                        Array.Copy(alloc_data.reservedtobefreed, 0, newbuffer, 0, alloc_data.rtbf_size);
                    }

                    alloc_data.reservedtobefreed = newbuffer;
                    alloc_data.rtbf_size = newsize;
                    alloc_data.reservedtobefreed[alloc_data.rtbf_index++] = blocknr;
                    // return;
//                 }
//
//                 /* this should never happen */
//                 DB(Trace(10,"ResToBeFreed","reserved to be freed cache full\n"));
// #ifdef BETAVERSION
//                 ErrorMsg (AFS_BETA_WARNING_1, NULL, g);
// #endif
//                 /* hope nobody allocates this block before the disk has been
//                  * updated
//                  */
//                 FreeReservedBlock (blocknr, g);
                    Allocation.FreeReservedBlock(blocknr, g);
                }
            }
        }

/* Makes a cached block ready for reuse:
** - Remove from queue
** - (dirblock) Decouple all references to the block
** - wipe memory
** NOTE: NOT REMOVED FROM LRU!
*/
        public static void FlushBlock(CachedBlock block, globaldata g)
        {
            // lockentry_t *le;
            //
            // DB(Trace(10,"FlushBlock","Flushing block %lx\n", block->blocknr));

            /* remove block from blockqueue */
            // MinRemove(block);
            Macro.MinRemove(block, g);
            Macro.MinRemove(new LruCachedBlock(block), g);

            /* decouple references */
            if (Macro.IsDirBlock(block))
            {
                /* check fileinfo references */
                for (var node = block.volume.fileentries.First; node != null; node = node.Next)
                {
                    /* only dirs and files have fileinfos that need to be updated,
                    ** but the volume * pointer of volumeinfos never points to
                    ** a cached block, so the type != ETF_VOLUME check is not
                    ** necessary. Just check the dirblockpointer
                    */
                    var le = node.Value;
                    if (le.le.info.file.dirblock == block)
                    {
                        le.le.dirblocknr = block.blocknr;

                        // le->le.dirblockoffset = (UBYTE *)le->le.info.file.direntry - (UBYTE *)block;
                        // TODO: How to do calculate dirblockoffset in C#
                        // le.le.dirblockoffset = le.le.info.file.direntry - block;
// #if DELDIR
                        le.le.info.deldir.special = Constants.SPECIAL_FLUSHED; /* flushed reference */
// #else
//                      le.Value.le.info.direntry = null;
// #endif
                        le.le.info.file.dirblock = null;
                    }

                    /* exnext references */
                    if (le.le.type.dir == ListType.ListTypeDir.Dir && le.nextentry.dirblock == block)
                    {
                        le.nextdirblocknr = block.blocknr;
                        // le->nextdirblockoffset = (UBYTE *)le->nextentry.direntry - (UBYTE *)block;
                        // TODO: How to do calculate dirblockoffset in C#
                        // le.nextdirblockoffset = le.nextentry.direntry - block;
// #if DELDIR
// le->nextentry.direntry = (struct direntry *)SPECIAL_FLUSHED;
                        le.nextentry.direntry = new direntry
                        {
                            next = Constants.SPECIAL_FLUSHED
                        };
// #else
//                         le.Value.le.nextentry.direntry = NULL;
// #endif
                        le.nextentry.dirblock = null;
                    }
                }
            }

            /* wipe memory */
            //memset(block, 0, SIZEOF_CACHEDBLOCK);
            ClearBlock(block);
        }

        private static void ClearBlock(CachedBlock cachedBlock)
        {
            cachedBlock.blocknr = 0;
            cachedBlock.changeflag = false;
            cachedBlock.oldblocknr = 0;
            cachedBlock.used = 0;
            cachedBlock.blk = null;
        }
    }
}