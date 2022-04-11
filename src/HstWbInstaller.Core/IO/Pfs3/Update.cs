namespace HstWbInstaller.Core.IO.Pfs3
{
    using System;
    using Blocks;

    public static class Update
    {
/* --> part of update
 * marks a directory or anodeblock dirty. Nothing happens if it already
 * was dirty. If it wasn't, the block will be reallocated and marked dirty.
 * If the reallocation fails, an error is displayed.
 *
 * result: TRUE = was clean; FALSE: was already dirty
 * 
 * LOCKing the block until next packet proves to be too restrictive,
 * so unlock afterwards.
 */
        public static bool MakeBlockDirty(CachedBlock blk, globaldata g)
        {
            uint blocknr;
            ushort oldlock;

            if (!blk.changeflag)
            {
                g.dirty = true;
                oldlock = blk.used;
                Cache.LOCK(blk, g);

                blocknr = Allocation.AllocReservedBlock(g);
                if (blocknr != 0)
                {
                    blk.oldblocknr = blk.blocknr;
                    blk.blocknr = blocknr;
                    UpdateBlocknr(blk, blocknr, g);
                }
                else
                {
// #ifdef BETAVERSION
//                     ErrorMsg(AFS_BETA_WARNING_2, NULL, g);
// #endif
                    blk.changeflag = true;
                }

                blk.used = oldlock;    // unlock block
                return true;
            }
            else
            {
                return false;
            }
        }

        public static void UpdateBlocknr(CachedBlock blk, uint newblocknr, globaldata g)
        {
            switch (blk.blk.id)
            {
                case Constants.DBLKID:    /* dirblock */
                    UpdateDBLK (blk, newblocknr, g);
                    break;

                case Constants.ABLKID:    /* anodeblock */
                    UpdateABLK (blk, newblocknr, g);
                    break;

                case Constants.IBLKID:    /* indexblock */
                    UpdateIBLK (blk, newblocknr, g);
                    break;

                case Constants.BMBLKID:   /* bitmapblock */
                    UpdateBMBLK (blk, newblocknr, g);
                    break;

                case Constants.BMIBLKID:  /* bitmapindexblock */
                    UpdateBMIBLK (blk, newblocknr, g);
                    break;

                case Constants.EXTENSIONID:   /* rootblockextension */
                    UpdateRBlkExtension (blk, newblocknr, g);
                    break;

                case Constants.DELDIRID:  /* deldir */
                    UpdateDELDIR (blk, newblocknr, g);
                    break;

                case Constants.SBLKID:	/* superblock */
                    UpdateSBLK (blk, newblocknr, g);
                    break;
            }
        }
        
        public static void UpdateDBLK(CachedBlock blk, uint newblocknr, globaldata g)
        {
            throw new NotImplementedException();
        }

        public static void UpdateABLK(CachedBlock blk, uint newblocknr, globaldata g)
        {
            throw new NotImplementedException();
        }

        public static void UpdateIBLK(CachedBlock blk, uint newblocknr, globaldata g)
        {
            throw new NotImplementedException();
        }

        public static void UpdateSBLK(CachedBlock blk, uint newblocknr, globaldata g)
        {
            throw new NotImplementedException();
        }
            
        public static void UpdateBMBLK(CachedBlock blk, uint newblocknr, globaldata g)
        {
            throw new NotImplementedException();
        }

            
        public static void UpdateBMIBLK(CachedBlock blk, uint newblocknr, globaldata g)
        {
            throw new NotImplementedException();
        }

// #if VERSION23
        public static void UpdateRBlkExtension(CachedBlock blk, uint newblocknr, globaldata g)
        {
            throw new NotImplementedException();
        }
// #endif

        public static void UpdateDELDIR(CachedBlock blk, uint newblocknr, globaldata g)
        {
            throw new NotImplementedException();
        }

/* Update datestamp (copy from rootblock
 * Call before writing block (lru.c)
 */
        public static void UpdateDatestamp(CachedBlock blk, globaldata g)
        {
            // struct cdirblock *dblk = (struct cdirblock *)blk;
            // struct crootblockextension *rext = (struct crootblockextension *)blk;

            // switch (((UWORD *)blk->data)[0])
            switch (blk.blk.id)
            {
                case Constants.DBLKID:    /* dirblock */
                case Constants.ABLKID:    /* anodeblock */
                case Constants.IBLKID:    /* indexblock */
                case Constants.BMBLKID:   /* bitmapblock */
                case Constants.BMIBLKID:  /* bitmapindexblock */
                case Constants.DELDIRID:  /* deldir */
                case Constants.SBLKID:	/* superblock */
                    // dblk->blk.datestamp = g->currentvolume->rootblk->datestamp;
                    // break;

                case Constants.EXTENSIONID:   /* rootblockextension */
                    // rext->blk.datestamp = g->currentvolume->rootblk->datestamp;
                    blk.blk.datestamp = g.currentvolume.rootblk.Datestamp;
                    break;
            }
        }

        public static bool UpdateDisk(globaldata g)
        {
            throw new NotImplementedException();
        }
    }
}