namespace HstWbInstaller.Core.IO.Pfs3.Blocks
{
    public class BitmapBlock : IBlock
    {
/* structure for both normal as reserved bitmap
 * normal: normal clustersize
 * reserved: directly behind rootblock. As long as necessary
 */
        // typedef struct bitmapblock
        // {
        //     UWORD id;               /* BM (bitmap block)                */
        //     UWORD not_used;
        //     ULONG datestamp;
        //     ULONG seqnr;
        //     ULONG bitmap[0];        /* the bitmap.                      */
        // } bitmapblock_t;

        public byte[] BlockBytes { get; set; }

        public ushort id { get; set; }
        public ushort not_used_1 { get; set; }
        public uint datestamp { get; set; }
        public uint seqnr;
        public uint[] bitmap; /* the bitmap.                      */
        
        public BitmapBlock(int blockSize, globaldata g)
        {
            id = Constants.BMBLKID; /* BM (bitmap block)                */

            bitmap = new uint[g.glob_allocdata.longsperbmb];
            for (var i = 0; i < g.glob_allocdata.longsperbmb; i++)
            {
                bitmap[i] = 0xFFFFFFFF;
            }
        }
    }
}