namespace HstWbInstaller.Core.IO.Pfs3.Blocks
{
    public class dirblock : IBlock
    {
        // struct dirblock 
        // {
        //     UWORD id;               /* 'DB'                             */
        //     UWORD not_used;
        //     ULONG datestamp;
        //     UWORD not_used_2[2];
        //     ULONG anodenr;          /* anodenr belonging to this directory (points to FIRST block of dir) */
        //     ULONG parent;           /* parent                           */
        //     UBYTE entries[0];       /* entries                          */
        // };        
        
        public byte[] BlockBytes { get; set; }
        
        public ushort id { get; set; }
        public ushort not_used_1 { get; set; }
        public uint datestamp { get; set; }
        public uint anodenr { get; set; }
        public uint parent { get; set; }
        public byte[] entries { get; set; }

        public dirblock(globaldata g)
        {
            id = Constants.DBLKID;
            entries = new byte[SizeOf.DirBlock.Entries(g)];
        }
    }
}