namespace HstWbInstaller.Core.IO.Pfs3.Blocks
{
    /// <summary>
    /// cache block.
    /// cbitmapblock, cindexblock, canodeblock, cdirblock, cdeldirblock, crootblockextension, (cachedblock)
    /// </summary>
    public class CachedBlock
    {
        private readonly int blockSize;

        private readonly globaldata g;
        /* Cached blocks in general
        */
        // struct cachedblock
        // {
        //     struct cachedblock	*next;
        //     struct cachedblock	*prev;
        //     struct volumedata	*volume;
        //     ULONG	blocknr;				// the current (new) blocknumber of the block
        //     ULONG	oldblocknr;				// the blocknr before reallocation. NULL if not reallocated.
        //     UWORD	used;					// block locked if used == g->locknr
        //     UBYTE	changeflag;				// dirtyflag
        //     UBYTE	dummy;					// pad to make offset even
        //     UBYTE	data[0];				// the datablock;
        // };
        
        public volumedata volume { get; set; }
        
        /// <summary>
        /// the current (new) blocknumber of the block
        /// </summary>
        public uint blocknr { get; set; }
        
        /// <summary>
        /// the blocknr before reallocation. NULL if not reallocated.
        /// </summary>
        public uint oldblocknr { get; set; }
        
        /// <summary>
        /// block locked if used == g->locknr
        /// </summary>
        public ushort used { get; set; }
        
        /// <summary>
        /// dirtyflag
        /// </summary>
        public bool changeflag { get; set; }

        //UBYTE	dummy;					// pad to make offset even
        
        public IBlock blk;

        public CachedBlock(int blockSize, globaldata g)
        {
            this.blockSize = blockSize;
            this.g = g;
        }

        public anodeblock ANodeBlock
        {
            get
            {
                if (blk == null)
                {
                    blk = new anodeblock(blockSize);
                }
                return blk as anodeblock;
            }
        }

        public indexblock IndexBlock
        {
            get
            {
                if (blk == null)
                {
                    blk = new indexblock(blockSize);
                }
                return blk as indexblock;
            }
        }

        public rootblockextension rblkextension
        {
            get
            {
                if (blk == null)
                {
                    blk = new rootblockextension(blockSize);
                }
                return blk as rootblockextension;
            }
        }

        public deldirblock deldirblock
        {
            get
            {
                if (blk == null)
                {
                    blk = new deldirblock(blockSize);
                }
                return blk as deldirblock;
            }
        }

        public dirblock dirblock
        {
            get
            {
                if (blk == null)
                {
                    blk = new dirblock(blockSize);
                }
                return blk as dirblock;
            }
        }

        public BitmapBlock BitmapBlock
        {
            get
            {
                if (blk == null)
                {
                    blk = new BitmapBlock(blockSize, g);
                }
                return blk as BitmapBlock;
            }
        }
    }
}