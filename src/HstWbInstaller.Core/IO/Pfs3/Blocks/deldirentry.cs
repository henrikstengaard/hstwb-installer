namespace HstWbInstaller.Core.IO.Pfs3.Blocks
{
    using System;

    public class deldirentry
    {
        // struct deldirentry
        // {
        //     ULONG anodenr;			/* anodenr							*/
        //     ULONG fsize;			/* size of file						*/
        //     UWORD creationday;		/* datestamp						*/
        //     UWORD creationminute;
        //     UWORD creationtick;
        //     UBYTE filename[16];		/* filename; filling up to 30 chars	*/
        //     // was previously filename[18]
        //     // now last two bytes used for extended file size
        //     UWORD fsizex;			/* extended bits 32-47 of fsize		*/
        // };
        
        public uint anodenr;			/* anodenr							*/
        public uint fsize;			/* size of file						*/
        /* datestamp						*/
        public DateTime CreationDate { get; set; }
        public string filename;		/* filename; filling up to 30 chars	*/
        // was previously filename[18]
        // now last two bytes used for extended file size
        public ushort fsizex;			/* extended bits 32-47 of fsize		*/
        
        public const int Size = SizeOf.ULONG * 2 + SizeOf.UWORD * 3 + 16 + SizeOf.UWORD;

    }
}