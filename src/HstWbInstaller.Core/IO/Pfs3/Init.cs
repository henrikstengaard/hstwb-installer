namespace HstWbInstaller.Core.IO.Pfs3
{
    using System;
    using System.Collections.Generic;
    using System.Threading.Tasks;
    using Blocks;

    public static class Init
    {
        /**********************************************************************/
        /*                             INITIALIZE                             */
        /*                             INITIALIZE                             */
        /*                             INITIALIZE                             */
        /**********************************************************************/
        public static void Initialize(globaldata g)
        {
            // init.c

            // g->blocksize = g->dosenvec->de_SizeBlock << 2;
            if (g.blocksize == 0)
            {
                throw new ArgumentException("Block size is 0", nameof(globaldata.blocksize));
            }
            
            var t = g.blocksize;
            int i;
            for (i = -1; t != 0; i++)
                t >>= 1;
            g.blockshift = (ushort)i;
            g.directsize = 16 * 1024 >> i;
            
            /* mode now always big */
            g.harddiskmode = true;     
            
            /* data cache */
            g.dc = new diskcache
            {
                size = Constants.DATACACHELEN,
                mask = Constants.DATACACHEMASK,
                roving = 0,
                ref_ = new reftable[Constants.DATACACHELEN],
                data = new byte[Constants.DATACACHELEN * g.blocksize]
            };

            for (i = 0; i < g.dc.ref_.Length; i++)
            {
                g.dc.ref_[i] = new reftable();
            }
        }
        
        /* Reconfigure the filesystem from a rootblock
        ** GetDriveGeometry already called by GetCurrentRoot, which does
        ** g->firstblock and g->lastblock.
        ** rootblockextension must have been loaded
        */
        public static async Task InitModules(volumedata volume, bool formatting, globaldata g)
        {
            var rootBlock = volume.rootblk;
            var blk = volume.rblkextension.rblkextension;

            g.RootBlock = rootBlock;
            g.uip = false;
            g.harddiskmode = rootBlock.Options.HasFlag(RootBlock.DiskOptionsEnum.MODE_HARDDISK);
            g.anodesplitmode = rootBlock.Options.HasFlag(RootBlock.DiskOptionsEnum.MODE_SPLITTED_ANODES);
            g.dirextension = rootBlock.Options.HasFlag(RootBlock.DiskOptionsEnum.MODE_DIR_EXTENSION);
	        g.deldirenabled = rootBlock.Options.HasFlag(RootBlock.DiskOptionsEnum.MODE_DELDIR) && 
                               g.dirextension && blk.deldirsize > 0;
            g.SuperMode = rootBlock.Options.HasFlag(RootBlock.DiskOptionsEnum.MODE_SUPERINDEX);
            g.fnsize = (ushort)(volume.rblkextension != null ? blk.fnsize : 32);
            if (g.fnsize == 0) g.fnsize = 32;
            g.largefile = rootBlock.Options.HasFlag(RootBlock.DiskOptionsEnum.MODE_LARGEFILE) && 
                          g.dirextension && Constants.LARGE_FILE_SIZE;

            await InitAnodes(volume, formatting, g);
            InitAllocation(volume, g);

            if (!formatting)
            {
                // DoPostponed(volume, g);
            }
        }
        
        public static async Task InitAnodes(volumedata volume, bool formatting, globaldata g)
        {
            if(!g.harddiskmode)
            {
                throw new Exception("AFS_ERROR_ANODE_INIT");
            }

            // g->getanodeblock = big_GetAnodeBlock;
            // reference to method

            var andata = g.glob_anodedata;
            andata.curranseqnr = (ushort)(volume.rblkextension != null ? volume.rblkextension.rblkextension.curranseqnr : 0);
            //andata.anodesperblock = (volume->rootblk->reserved_blksize - sizeof(anodeblock_t)) / sizeof(anode_t);
            //andata.indexperblock = (volume->rootblk->reserved_blksize - sizeof(indexblock_t)) / sizeof(LONG);
            andata.anodesperblock = (ushort)((volume.rootblk.ReservedBlksize - SizeOf.ANODEBLOCK_T) / SizeOf.ANODE_T);
            andata.indexperblock = (ushort)((volume.rootblk.ReservedBlksize - SizeOf.INDEXBLOCK_T) / 4);
            andata.maxanodeseqnr = (uint)(g.SuperMode ?
                ((Constants.MAXSUPER+1) * andata.indexperblock * andata.indexperblock * andata.anodesperblock - 1) :
                (Constants.MAXSMALLINDEXNR * andata.indexperblock - 1));
            andata.reserved = (ushort)(andata.anodesperblock - Constants.RESERVEDANODES);
            await anodes.MakeAnodeBitmap(formatting, g);
        }
        
/* MODE_BIG has indexblocks, and negative blocknrs indicating freenode
** blocks instead of anodeblocks
*/
        public static async Task<CachedBlock> big_GetAnodeBlock(ushort seqnr, globaldata g)
        {
            uint blocknr;
            uint temp;
            // struct canodeblock *ablock;
            // struct cindexblock *indexblock;
            var volume = g.currentvolume;
            var andata = g.glob_anodedata;
            
            temp = divide(seqnr, andata.indexperblock);

            /* not in cache, put it in */
            /* get the indexblock */
            var indexblock = await anodes.GetIndexBlock((ushort)temp /*& 0xffff*/, g);
            if (indexblock == null)
            {
                //DBERR(ErrorTrace(5, "GetAnodeBlock","ERR: index not found. %lu %lu %08lx\n", seqnr, andata.indexperblock, temp));
                return null;
            }

            /* get blocknr */
            if ((blocknr = (uint)indexblock.IndexBlock.index[temp >> 16]) == 0)
            {
                //DBERR(ErrorTrace(5,"GetAnodeBlock","ERR: index zero %lu %lu %08lx\n", seqnr, andata.indexperblock, temp));
                return null;
            }

            /* check cache */
            var ablock = Lru.CheckCache(volume.anblks, Constants.HASHM_ANODE, blocknr, g);
            if (ablock != null)
                return ablock;

            if ((ablock = await Lru.AllocLRU(g)) == null)
            {
                //     DBERR(ErrorTrace(5,"GetAnodeBlock","ERR: alloclru failed\n"));
                return null;
            }
            
            //DBERR(ErrorTrace(10,"GetAnodeBlock", "seqnr = %lu blocknr = %lu\n", seqnr, blocknr));

            /* read it */
            IBlock blk;
            if ((blk = await Disk.RawRead<anodeblock>(g.currentvolume.rescluster, blocknr, g)) == null)
            {
                //DB(Trace(5,"GetAnodeBlock","Read ERR: seqnr = %lu blocknr = %lx\n", seqnr, blocknr));
                Lru.FreeLRU(ablock, g);
                return null;
            }
            ablock.blk = blk;

            /* check it */
            if (ablock.blk.id != Constants.ABLKID)
            {
                // ULONG args[2];
                // args[0] = ablock->blk.id;
                // args[1] = blocknr;
                // FreeLRU ((struct cachedblock *)ablock);
                // ErrorMsg (AFS_ERROR_DNV_WRONG_ANID, args, g);
                Lru.FreeLRU(ablock, g);
                return null;
            }

            /* initialize it */
            ablock.volume     = volume;
            ablock.blocknr    = blocknr;
            ablock.used       = 0;
            ablock.changeflag = false;
            Macro.Hash(ablock, volume.anblks, Constants.HASHM_ANODE);

            return ablock;
        }
        
        /*
         * InitAllocation
         *
         * currentvolume has to be ok.
         */
        public static void InitAllocation(volumedata volume, globaldata g)
        {
            uint t;
            var rootblock = volume.rootblk;

            if (g.harddiskmode)
            {
                var longsPerBmb = rootblock.LongsPerBmb;
                var alloc_data = g.glob_allocdata;            
                alloc_data.clean_blocksfree = (uint)rootblock.BlocksFree;
                alloc_data.alloc_available = (uint)(rootblock.BlocksFree - rootblock.AlwaysFree);
                alloc_data.longsperbmb = (uint)longsPerBmb;

                t = (uint)((volume.numblocks - (rootblock.LastReserved + 1) + 31) / 32);
                t = (uint)((t + longsPerBmb - 1 ) / longsPerBmb);
                alloc_data.no_bmb = t;
                alloc_data.bitmapstart = (uint)(rootblock.LastReserved + 1);
                //memset (alloc_data.tobefreed, 0, TBF_CACHE_SIZE*2*sizeof(ULONG));
                alloc_data.tobefreed = new uint[Constants.TBF_CACHE_SIZE][];
                for (var i = 0; i < Constants.TBF_CACHE_SIZE; i++)
                {
                    alloc_data.tobefreed[i] = new uint[2];
                }
                alloc_data.tobefreed_index = 0;
                alloc_data.tbf_resneed = 0;
                //alloc_data.res_bitmap = (bitmapblock_t *)(rootblock+1);   /* bitmap directly behind rootblock */
                alloc_data.res_bitmap = new BitmapBlock((int)g.blocksize, g);

                if (volume.rblkextension != null)
                {
                    var blk = volume.rblkextension.rblkextension;
                    if (!(rootblock.Options.HasFlag(RootBlock.DiskOptionsEnum.MODE_EXTROVING)))
                    {
                        rootblock.Options |= RootBlock.DiskOptionsEnum.MODE_EXTROVING;
                        g.dirty = true;
                        blk.reserved_roving *= 32;
                    }
                    alloc_data.res_roving = blk.reserved_roving;
                    alloc_data.rovingbit = blk.rovingbit;
                } 
                else
                {
                    alloc_data.res_roving = 0;
                    alloc_data.rovingbit = 0;
                }

                alloc_data.numreserved = (uint)((rootblock.LastReserved - rootblock.FirstReserved + 1) / volume.rescluster);
                alloc_data.reservedtobefreed = null;
                alloc_data.rtbf_size = 0;
                alloc_data.rtbf_index = 0;
                alloc_data.res_alert = false;
            }
            else
            {
                throw new Exception("AFS_ERROR_ANODE_INIT");
            }
        }
        
/*
;-----------------------------------------------------------------------------
;	ULONG divide (ULONG d0, UWORD d1)
;-----------------------------------------------------------------------------
*/
        public static uint divide(uint d0, uint d1)
        {
            uint q = d0 / d1;
            /* NOTE: I doubt anything depends on this, but lets simulate 68k divu overflow anyway - Piru */
            if (q > 65535UL) return d0;
            return ((d0 % d1) << 16) | q;
        }
    }
}