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
        
        public byte[] BlockBytes { get; set; }

        public ushort id { get; set; }
        public ushort not_used_1 { get; set; }
        public uint datestamp { get; set; }
        public uint seqnr;
        public int[] index;          /* the indices                      */

        public indexblock(int blockSize)
        {
            id = Constants.IBLKID;
            index = new int[(blockSize - SizeOf.UWORD * 2 - SizeOf.ULONG * 2) / SizeOf.LONG];
        }
    }
}