namespace HstWbInstaller.Core.IO.Pfs3.Blocks
{
    using System;

    public class deldirentry
    {
        public uint anodenr;			/* anodenr							*/
        public uint fsize;			/* size of file						*/
        /* datestamp						*/
        public DateTime CreationDate { get; set; }
        public string filename;		/* filename; filling up to 30 chars	*/
        // was previously filename[18]
        // now last two bytes used for extended file size
        public ushort fsizex;			/* extended bits 32-47 of fsize		*/
    }
}