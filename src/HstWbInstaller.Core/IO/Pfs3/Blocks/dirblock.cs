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
        
        public ushort id { get; set; }
        public ushort not_used { get; set; }
        public uint datestamp { get; set; }
        public uint anodenr { get; set; }
        public uint parent { get; set; }
        public uint[] entries { get; set; }

        public dirblock()
        {
            id = Constants.DBLKID;
        }
    }
}