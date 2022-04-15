namespace HstWbInstaller.Core.IO.Pfs3
{
    using System.IO;
    using Blocks;

    public class globaldata
    {
        public RootBlock RootBlock;
        public uint NumBuffers;
        public lru_data_s glob_lrudata;
        
        /* LRU stuff */
        public bool uip;                           /* update in progress flag              */
        public ushort locknr;                       /* prevents blocks from being flushed   */
        
        // // ULONG de_SizeBlock;	     /* in longwords: Physical disk block size */
        // public uint SizeBlock;
        
        public uint blocksize;                    /* g->dosenvec->de_SizeBlock << 2       */
        public ushort blockshift;                   /* 2 log van block size                 */
        public ushort fnsize;						/* filename size (18+)					*/
        public int directsize;                   /* number of blocks after which direct  */

        public long[] allocbufmem;
        
        public uint firstblock;/* first and last block of partition    */
        public uint lastblock;

        /* 1 if 'ACTION_WRITE_PROTECTED'     	*/
        public bool softprotect;
        
        public volumedata currentvolume;
        public bool dirty;
        public long protectkey;
        public bool harddiskmode;
        public bool anodesplitmode;
        public bool dirextension;
        public bool largefile;
        public bool deldirenabled;
        public anode_data_s glob_anodedata;
        public allocation_data_s glob_allocdata;
        
        // stream for data io
        public Stream stream;
        
        public ushort infoblockshift;
        public bool updateok;

        public globaldata(Stream stream)
        {
            glob_lrudata = new lru_data_s();
            glob_anodedata = new anode_data_s();
            glob_allocdata = new allocation_data_s();
            this.stream = stream;
            dc = new diskcache();
        }

        public uint TotalSectors { get; set; }
        public bool SuperMode { get; set; }
        
        public diskcache dc;                /* cache to make '196 byte mode' faster */

    }
}