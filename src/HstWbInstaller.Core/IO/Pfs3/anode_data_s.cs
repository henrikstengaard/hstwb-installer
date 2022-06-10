namespace HstWbInstaller.Core.IO.Pfs3
{
    public class anode_data_s
    {
        public ushort curranseqnr;        /* current anode seqnr for anode allocation */
        public ushort indexperblock;      /* ALSO used by allocation (for bitmapindex blocks) */
        public uint maxanodeseqnr;		/* max anode seqnr */
        public ushort anodesperblock;     /* number of anodes that fit in one block */
        public ushort reserved;           /* offset of first reserved anode within an anodeblock */
        public uint[] anblkbitmap;       /* anodeblock full-flag bitmap */
        public uint anblkbitmapsize;    /* size of anblkbitmap */
        public uint maxanseqnr;         /* current maximum anodeblock seqnr */
    }
}