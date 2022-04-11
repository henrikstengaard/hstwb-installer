namespace HstWbInstaller.Core.IO.Pfs3.Blocks
{
    using Pfs3;

    public class anodeblock : IBlock
    {
        // typedef struct anodeblock
        // {
        //     UWORD id;               /* AB                               */
        //     UWORD not_used;
        //     ULONG datestamp;
        //     ULONG seqnr;
        //     ULONG not_used_2;
        //     struct anode nodes[0];
        // } anodeblock_t;
        
        public ushort id { get; set; }
        public ushort not_used { get; set; }
        public uint datestamp { get; set; }
        public uint seqnr;
        public uint not_used_2;
        public anode[] nodes;

        public anodeblock()
        {
            id = Constants.ABLKID; /* AB                               */
        }
    }
}