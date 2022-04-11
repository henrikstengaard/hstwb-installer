namespace HstWbInstaller.Core.IO.Pfs3
{
    using System.Collections.Generic;
    using Blocks;

    public class lru_data_s
    {
        public LinkedList<CachedBlock> LRUqueue;
        public LinkedList<CachedBlock> LRUpool;
        public uint poolsize;
        public LinkedList<CachedBlock> LRUarray;
        public ushort reservedBlksize;
    };
}