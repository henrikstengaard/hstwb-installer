namespace HstWbInstaller.Core.IO.Pfs3.Blocks
{
    public class direntry
    {
        // struct direntry
        // {
        //     UBYTE next;             /* sizeof direntry                  */
        //     BYTE  type;             /* dir, file, link etc              */
        //     ULONG anode;            /* anode number                     */
        //     ULONG fsize;            /* sizeof file                      */
        //     UWORD creationday;      /* days since Jan. 1, 1978 (like ADOS; WORD instead of LONG) */
        //     UWORD creationminute;   /* minutes past modnight            */
        //     UWORD creationtick;     /* ticks past minute                */
        //     UBYTE protection;       /* protection bits (like DOS)       */
        //     UBYTE nlength;          /* lenght of filename               */
        //     UBYTE startofname;      /* filename, followed by filenote length & filenote */
        //     UBYTE pad;              /* make size even                   */
        // };
        
        public byte next;             /* sizeof direntry                  */
        public byte  type;             /* dir, file, link etc              */
        public uint anode;            /* anode number                     */
        public uint fsize;            /* sizeof file                      */
        public ushort creationday;      /* days since Jan. 1, 1978 (like ADOS; WORD instead of LONG) */
        public ushort creationminute;   /* minutes past modnight            */
        public ushort creationtick;     /* ticks past minute                */
        public byte protection;       /* protection bits (like DOS)       */
        public byte nlength;          /* lenght of filename               */
        public byte startofname;      /* filename, followed by filenote length & filenote */
        public byte pad;              /* make size even                   */
    }
}