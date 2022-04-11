namespace HstWbInstaller.Core.IO.Pfs3.Blocks
{
    public class BitmapBlock : IBlock
    {
/* structure for both normal as reserved bitmap
 * normal: normal clustersize
 * reserved: directly behind rootblock. As long as necessary
 */
        public ushort id { get; set; }
        public ushort not_used { get; set; }
        public uint datestamp { get; set; }
        public uint seqnr;
        public uint[] bitmap; /* the bitmap.                      */
        
        public BitmapBlock()
        {
            id = Constants.BMBLKID; /* BM (bitmap block)                */
        }
    }
}