namespace HstWbInstaller.Core.IO.Pfs3.Blocks
{
    using System;

    public class deldirblock : IBlock
    {
        // struct deldirblock
        // {
        //     UWORD id;				/* 'DD'								*/
        //     UWORD not_used;
        //     ULONG datestamp;
        //     ULONG seqnr;
        //     UWORD not_used_2[2];
        //     UWORD not_used_3;		/* roving in older versions	(<17.9)	*/	
        //     UWORD uid;				/* user id							*/
        //     UWORD gid;				/* group id							*/
        //     ULONG protection;
        //     UWORD creationday;
        //     UWORD creationminute;
        //     UWORD creationtick;
        //     struct deldirentry entries[0];	/* 31 entries				*/
        // };

        public byte[] BlockBytes { get; set; }

        public ushort id { get; set; }
        public ushort not_used_1 { get; set; }
        public uint datestamp { get; set; }
        public uint seqnr { get; set; }
        public ushort uid { get; set; }
        public ushort gid { get; set; }
        public uint protection { get; set; }
        public DateTime CreationDate { get; set; }
        public deldirentry[] entries { get; set; }

        public deldirblock(globaldata g)
        {
            id = Constants.DELDIRID;
            entries = new deldirentry[(g.RootBlock.ReservedBlksize - SizeOf.UWORD * 2 - SizeOf.ULONG * 2 - SizeOf.UWORD * 4 -
                                       SizeOf.ULONG - SizeOf.UWORD * 3) / deldirentry.Size];
            for (var i = 0; i < entries.Length; i++)
            {
                entries[i] = new deldirentry();
            }
        }
    }
}