namespace HstWbInstaller.Core.IO.Pfs3
{
    using System;
    using System.Threading.Tasks;
    using Blocks;

    public static class Directory
    {
        public static bool IsDelDir(objectinfo oi) => oi.deldir.special == Constants.SPECIAL_DELDIR;
        public static bool IsDelFile(objectinfo oi) => oi.deldir.special == Constants.SPECIAL_DELFILE;
        
        public static async Task<CachedBlock> MakeDirBlock(uint blocknr, uint anodenr, uint rootanodenr, uint parentnr, globaldata g)
        {
            // struct canode anode;
            // struct cdirblock *blk;
            var volume = g.currentvolume;

            //DB(Trace(10,"MakeDirBlock","blocknr = %lx\n", blocknr));

            /* fill in anode (allocated by MakeDirEntry) */
            var anode = new canode
            {
                clustersize = 1,
                blocknr = blocknr,
                next = 0
            };
            await anodes.SaveAnode(anode, anodenr, g);

            var blk = await Lru.AllocLRU(g);
            var dirblock = new dirblock(g);
            dirblock.anodenr = rootanodenr;
            dirblock.parent = parentnr;
            blk.blk = dirblock;
            blk.volume = volume;
            blk.blocknr = blocknr;
            blk.oldblocknr = 0;
            blk.changeflag = true;

            Macro.Hash(blk, volume.dirblks, Constants.HASHM_DIR);
            Cache.LOCK(blk, g);
            return blk;
        }      
        
        /* Set number of deldir blocks (Has to be single threaded)
 * If 0 then deldir is disabled (but MODE_DELDIR stays;
 * InitModules() detect that the number of deldirblocks is 0)
 * There must be a currentvolume
 * Returns error (0 = success)
 */
        public static async Task SetDeldir(int nbr, globaldata g) 
        {
            var rext = g.currentvolume.rblkextension;
            //struct cdeldirblock *ddblk, *next;
            CachedBlock ddblk;
            lockentry list;
            int i;
            //ULONG error = 0;

            /* check range */
            if (nbr < 0 || nbr > Constants.MAXDELDIR + 1)
            {
                // return ERROR_BAD_NUMBER;
                throw new Exception("ERROR_BAD_NUMBER");
            }

            /* check if there are locks on any deldir, delfile */
            for (var node = Macro.HeadOf(g.currentvolume.fileentries); node != null; node = node.Next)
            {
                list = node.Value;

                if (list == null)
                {
                    continue;
                }
                
                if (IsDelDir(list.le.info) || IsDelFile(list.le.info))
                {
                    // return ERROR_OBJECT_IN_USE;
                    throw new Exception("ERROR_OBJECT_IN_USE");
                }
            }

            await Update.UpdateDisk(g);

            /* flush cache */
            for (var node = Macro.HeadOf(g.currentvolume.deldirblks); node != null; node = node.Next)
            {
                ddblk = node.Value;
                Lru.FlushBlock(ddblk, g);
                // MinRemove(LRU_CHAIN(ddblk));
                // MinAddHead(&g->glob_lrudata.LRUpool, LRU_CHAIN(ddblk));
                Macro.MinRemove(ddblk, g);
                Macro.MinAddHead(g.glob_lrudata.LRUpool, new LruCachedBlock(ddblk));
                // i.p.v. FreeLRU((struct cachedblock *)ddblk, g);
            }

            /* free unwanted deldir blocks */
            var rext_blk = rext.rblkextension;
            for (i = nbr; i < rext_blk.deldirsize; i++)
            {
                Allocation.FreeReservedBlock(rext_blk.deldir[i], g);
                rext_blk.deldir[i] = 0;
            }

            /* allocate wanted ones */
            for (i = rext_blk.deldirsize; i < nbr; i++)
            {
                if (await NewDeldirBlock((ushort)i,g) == null)
                {
                    nbr = i+1;
                    // error = ERROR_DISK_FULL;
                    // break;
                    throw new Exception("ERROR_DISK_FULL");
                }
            }

            /* if deldir size increases, start roving in a the new area 
             * if deldir size decreases, start roving from the start
             */
            if (nbr > rext_blk.deldirsize)
                rext_blk.deldirroving = (ushort)(rext_blk.deldirsize * Constants.DELENTRIES_PER_BLOCK);
            else
                rext_blk.deldirroving = 0;

            /* enable/disable */
            rext_blk.deldirsize = (ushort)nbr;
            g.deldirenabled = nbr > 0;

            await Update.MakeBlockDirty(rext, g);
            await Update.UpdateDisk(g);
        }
        
        public static async Task<CachedBlock> NewDeldirBlock(ushort seqnr, globaldata g)
        {
            // cdeldirblock
            var volume = g.currentvolume;
            // struct crootblockextension *rext;
            CachedBlock ddblk;
            uint blocknr;

            var rext = volume.rblkextension;

            if (seqnr > Constants.MAXDELDIR)
            {
                // DB(Trace(5, "NewDelDirBlock", "seqnr out of range = %lx\n", seqnr));
                return null;
            }

            /* alloc block and LRU slot */
            if ((ddblk = await Lru.AllocLRU(g)) == null || (blocknr = Allocation.AllocReservedBlock(g)) == 0 )
            {
                if (ddblk != null)
                    Lru.FreeLRU(ddblk, g);
                return null;
            }

            /* make reference */
            var rext_blk = rext.rblkextension;
            rext_blk.deldir[seqnr] = blocknr;

            /* fill block */
            ddblk.volume     = volume;
            ddblk.blocknr    = blocknr;
            ddblk.used       = 0;
            var ddblk_blk = new deldirblock(g)
            {
                id = Constants.DELDIRID,
                seqnr = seqnr
            };
            ddblk.blk = ddblk_blk;
            ddblk.changeflag = true;
            ddblk_blk.protection		= Constants.DELENTRY_PROT;	/* re..re..re.. */
            ddblk_blk.CreationDate = volume.rootblk.CreationDate;
            // ddblk->blk.creationminute	= volume->rootblk->creationminute;
            // ddblk->blk.creationtick		= volume->rootblk->creationtick;

            /* add to cache and return */
            Macro.MinAddHead(volume.deldirblks, ddblk);
            return ddblk;
        }
        
    }
}