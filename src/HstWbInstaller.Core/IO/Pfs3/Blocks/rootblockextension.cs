namespace HstWbInstaller.Core.IO.Pfs3.Blocks
{
    using System;

    public class rootblockextension : IBlock
    {
        // struct rootblockextension
        // {
        //     UWORD id;					/* id ('EX') */
        //     UWORD not_used_1;
        //     ULONG ext_options;
        //     ULONG datestamp;
        //     ULONG pfs2version;			/* pfs2 revision under which the disk was formatted */
        //     UWORD root_date[3];			/* root directory datestamp */
        //     UWORD volume_date[3];		/* volume datestamp */
        //     struct postponed_op tobedone;	/* postponed operation (curr. only delete) */
        //     ULONG reserved_roving;		/* reserved roving pointer */
        //     UWORD rovingbit;			/* bitnr in rootblock->roving_ptr bitmap field */
        //     UWORD curranseqnr;			/* anodeallocation roving pointer */
        //     UWORD deldirroving;			/* deldir roving pointer */
        //     UWORD deldirsize;			/* size of deldir */
        //     UWORD fnsize;				/* filename size (18.1) */
        //     UWORD not_used_2[3];
        //     ULONG superindex[MAXSUPER + 1];		/* MODE_SUPERINDEX only. offset=64 $40 */
        //     UWORD dd_uid;				/* deldir user id (17.9)			*/
        //     UWORD dd_gid;				/* deldir group id					*/
        //     ULONG dd_protection;		/* deldir protection				*/
        //     UWORD dd_creationday;		/* deldir datestamp					*/
        //     UWORD dd_creationminute;
        //     UWORD dd_creationtick;
        //     UWORD not_used_3;
        //     ULONG deldir[32];			/* 32 deldir blocks					*/
        // };
        
        public byte[] BlockBytes { get; set; }
        
        public ushort id { get; set; }
        public ushort not_used_1 { get; set; }
        public uint datestamp { get; set; }
        public uint ext_options;
        public uint pfs2version;			/* pfs2 revision under which the disk was formatted */
        //UWORD root_date[3];			/* root directory datestamp */
        //UWORD volume_date[3];		/* volume datestamp */
        public DateTime RootDate;
        public DateTime VolumeDate;
        public postponed_op tobedone;	/* postponed operation (curr. only delete) */
        public uint reserved_roving { get; set; } /* reserved roving pointer */
        public ushort rovingbit;			/* bitnr in rootblock->roving_ptr bitmap field */
        public ushort curranseqnr;			/* anodeallocation roving pointer */
        public ushort deldirroving;			/* deldir roving pointer */
        public ushort deldirsize;			/* size of deldir */
        public ushort fnsize;				/* filename size (18.1) */
        //UWORD not_used_2[3];
        public uint[] superindex;		/* MODE_SUPERINDEX only. offset=64 $40 */
        public ushort dd_uid;				/* deldir user id (17.9)			*/
        public ushort dd_gid;				/* deldir group id					*/
        public uint dd_protection;		/* deldir protection				*/

        public DateTime dd_creationdate;
        // UWORD dd_creationday;		/* deldir datestamp					*/
        // UWORD dd_creationminute;
        // UWORD dd_creationtick;
        // UWORD not_used_3;
        public uint[] deldir;			/* 32 deldir blocks					*/

        public rootblockextension()
        {
            id = Constants.EXTENSIONID;
            superindex = new uint[Constants.MAXSUPER + 1];
            deldir = new uint[32];
            tobedone = new postponed_op();
        }
    }
}