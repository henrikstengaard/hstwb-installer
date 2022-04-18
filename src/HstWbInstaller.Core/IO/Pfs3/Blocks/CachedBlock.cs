namespace HstWbInstaller.Core.IO.Pfs3.Blocks
{
    /// <summary>
    /// cache block.
    /// cbitmapblock, cindexblock, canodeblock, cdirblock, cdeldirblock, crootblockextension, (cachedblock)
    /// </summary>
    public class CachedBlock
    {
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

        public IBlock blk { get; set; }

        public CachedBlock(globaldata g)
        {
            this.g = g;
        }

        public anodeblock ANodeBlock => blk as anodeblock;

        public indexblock IndexBlock => blk as indexblock;

        public rootblockextension rblkextension => blk as rootblockextension;

        public deldirblock deldirblock => blk as deldirblock;

        public dirblock dirblock => blk as dirblock;

        public BitmapBlock BitmapBlock => blk as BitmapBlock;
    }
}