namespace HstWbInstaller.Core.IO.Pfs3
{
    using System;
    using System.Collections.Generic;
    using System.Threading.Tasks;
    using Blocks;

    public static class Macro
    {
        /* macros on cachedblocks */
        public static bool IsDirBlock(CachedBlock blk) => blk.blk.id == Constants.DBLKID;
        public static bool IsAnodeBlock(CachedBlock blk) => blk.blk.id == Constants.ABLKID;
        public static bool IsIndexBlock(CachedBlock blk) => blk.blk.id == Constants.IBLKID;
        public static bool IsBitmapBlock(CachedBlock blk) => blk.blk.id == Constants.BMBLKID;
        public static bool IsBitmapIndexBlock(CachedBlock blk) => blk.blk.id == Constants.BMIBLKID;
        public static bool IsDeldir(CachedBlock blk) => blk.blk.id == Constants.DELDIRID;
        public static bool IsSuperBlock(CachedBlock blk) => blk.blk.id == Constants.SBLKID;

        /// <summary>
        /// remove node from any list it's added to. Amiga MinList exec
        /// </summary>
        /// <param name="node"></param>
        /// <param name="g"></param>
        public static void MinRemove(CachedBlock node, globaldata g)
        {
            // #define MinRemove(node) Remove((struct Node *)node)
            // remove() removes the node from any list it' added to
            
            g.glob_lrudata.LRUarray.Remove(node);
            g.glob_lrudata.LRUpool.Remove(node);
            g.glob_lrudata.LRUqueue.Remove(node);
        }

        /// <summary>
        /// add node to head of list. Amiga MinList exec
        /// </summary>
        /// <param name="list"></param>
        /// <param name="node"></param>
        /// <typeparam name="T"></typeparam>
        public static void MinAddHead<T>(LinkedList<T> list, T node)
        {
            // #define MinAddHead(list, node)  AddHead((struct List *)(list), (struct Node *)(node))
            list.AddFirst(node);
        }

        public static LinkedListNode<T> HeadOf<T>(LinkedList<T> list)
        {
            // #define HeadOf(list) ((void *)((list)->mlh_Head))
            return list.First;
        }
        
        public static async Task<CachedBlock> GetAnodeBlock(ushort seqnr, globaldata g)
        {
            // #define GetAnodeBlock(a, b) (g->getanodeblock)(a,b)
            // g->getanodeblock = big_GetAnodeBlock;
            return await Init.big_GetAnodeBlock(seqnr, g);
        }
        
        /// <summary>
        /// convert anodenr to subclass with seqnr and offset
        /// </summary>
        /// <param name="anodenr"></param>
        /// <returns></returns>
        public static anodenr SplitAnodenr(uint anodenr)
        {
            // typedef struct
            // {
            //     UWORD seqnr;
            //     UWORD offset;
            // } anodenr_t;
            return new anodenr
            {
                seqnr = (ushort)(anodenr >> 16),
                offset = (ushort)(anodenr & 0xFFFF)
            };
        }

        public static bool InPartition(uint blk, globaldata g)
        {
            return blk >= g.firstblock && blk <= g.lastblock;
        }
        
        public static void Hash(CachedBlock blk, LinkedList<CachedBlock>[] list, int mask)
        {
            // #define Hash(blk, list, mask)                           \
            //             MinAddHead(&list[(blk->blocknr/2)&mask], blk)
            MinAddHead(list[(blk.blocknr / 2) & mask], blk);
        }
        
        /*
         * Hashing macros
         */
        public static void ReHash(CachedBlock blk, LinkedList<CachedBlock>[] list, int mask, globaldata g)
        {
            // #define ReHash(blk, list, mask)                         \
            // {                                                       \
            //     MinRemove(blk);                                     \
            //     MinAddHead(&list[(blk->blocknr/2)&mask], blk);      \
            // }
            
            MinRemove(blk, g);
            MinAddHead(list[(blk.blocknr / 2) & mask], blk);
        }        
        
        public static bool IsEmptyDBlk(CachedBlock blk)
        {
            // #define IsEmptyDBlk(blk) (FIRSTENTRY(blk)->next == 0)
            return blk.deldirblock.entries.Length == 0;
        }
    }
}