namespace HstWbInstaller.Core.IO.Pfs3
{
    using System.Collections.Generic;
    using Blocks;

    public class lru_data_s
    {
        /* the LRU global data */
        // struct lru_data_s
        // {
        //     struct MinList LRUqueue;
        //     struct MinList LRUpool;
        //     ULONG poolsize;
        //     struct lru_cachedblock **LRUarray;
        //     UWORD reserved_blksize;
        // };
        
        public LinkedList<LruCachedBlock> LRUqueue;
        public LinkedList<LruCachedBlock> LRUpool;
        public uint poolsize;
        public LruCachedBlock[] LRUarray;
        public ushort reservedBlksize;
    };
}