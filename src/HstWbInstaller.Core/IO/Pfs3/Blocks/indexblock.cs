namespace HstWbInstaller.Core.IO.Pfs3.Blocks
{
    public class indexblock : IBlock
    {
        // typedef struct indexblock
        // {
        //     UWORD id;               /* AI or BI (anode- bitmap index)   */
        //     UWORD not_used;
        //     ULONG datestamp;
        //     ULONG seqnr;
        //     LONG index[0];          /* the indices                      */
        // } indexblock_t;        
        
        public ushort id { get; set; }
        public ushort not_used { get; set; }
        public uint datestamp { get; set; }
        public uint seqnr;
        public int[] index;          /* the indices                      */

        public indexblock()
        {
            id = Constants.IBLKID;
        }
    }
}