namespace HstWbInstaller.Core.IO.Pfs3
{
    using System;
    using System.ComponentModel.Design.Serialization;

    public static class Constants
    {
        // https://wiki.amigaos.net/wiki/Migration_Guide
        // -------
        // uint8 = UBYTE,	8 bit unsigned integer
        // uint32 = ULONG, 32 bit unsigned integer
        // uint16 =	UWORD, 16 bit unsigned integer

        /*
// Cached blocks in general

        struct cachedblock
        {
            struct cachedblock	*next;
            struct cachedblock	*prev;
            struct volumedata	*volume;
            ULONG	blocknr;				// overeenkomstig diskblocknr
            ULONG	oldblocknr;				// blocknr before reallocation. NULL if not reallocated.
            UWORD	used;					// block locked if used == g->locknr
            UBYTE	changeflag;				// dirtyflag
            UBYTE	dummy;					// pad to make offset even
            UBYTE	data[0];				// the datablock;
        };
*/

/* size of reserved blocks in bytes and blocks
 * place you can find rootblock
 */
        //public const long SIZEOF_RESBLOCK = 1024;
        /* size of reserved blocks in bytes and blocks
 * place you can find rootblock
 */
        //public const long SIZEOF_RESBLOCK (g->rootblock->reserved_blksize)
        //public const long SIZEOF_CACHEDBLOCK = (sizeof(struct cachedblock) + SIZEOF_RESBLOCK);
        //public const long SIZEOF_LRUBLOCK = (sizeof(struct lru_cachedblock) + SIZEOF_RESBLOCK);
        //public const long RESCLUSTER (g->currentvolume->rescluster)

/* info id's: delfile, deldir and flushed reference */
        public const byte SPECIAL_DELDIR = 1;
        public const byte SPECIAL_DELFILE = 2;
        public const byte SPECIAL_FLUSHED = 3;

        public const byte VERNUM = 19;
        public const byte REVNUM = 2;

        public const uint BOOTBLOCK1 = 0;
        public const uint BOOTBLOCK2 = 1;
        public const uint ROOTBLOCK = 2;

/* number of reserved anodes per anodeblock */
        public const int RESERVEDANODES = 6;

        public const bool LARGE_FILE_SIZE = false;

        /* limits */
        public const int MAXSMALLBITMAPINDEX = 4;

        public const int MAXBITMAPINDEX = 103;

        // was 28576. was 119837. Nu max reserved bitmap 256K.
        public const int MAXNUMRESERVED = 4096 + 255 * 1024 * 8;
        public const int MAXSUPER = 15;
        public const int MAXSMALLINDEXNR = 98;

        /* maximum disksize in sectors, limited by number of bitmapindexblocks
        * smalldisk = 10.241.440 blocks of 512 byte = 5G
        * normaldisk = 213.021.952 blocks of 512 byte = 104G
        * 2k reserved blocks = 104*509*509*32 blocks of 512 byte = 411G
        * 4k reserved blocks = 1,6T
        *  */
        public const short BITMAP_PAYLOAD_1K = 1024 / 4 - 3; // 253
        public const short BITMAP_PAYLOAD_2K = 2048 / 4 - 3; // 509
        public const short BITMAP_PAYLOAD_4K = 4096 / 4 - 3; // 1021

        public const long MAXSMALLDISK = (MAXSMALLBITMAPINDEX + 1) * BITMAP_PAYLOAD_1K * BITMAP_PAYLOAD_1K * 32;
        public const long MAXDISKSIZE1K = (MAXBITMAPINDEX + 1) * BITMAP_PAYLOAD_1K * BITMAP_PAYLOAD_1K * 32;
        public const long MAXDISKSIZE2K = (MAXBITMAPINDEX + 1) * BITMAP_PAYLOAD_2K * BITMAP_PAYLOAD_2K * 32;
        public const long MAXDISKSIZE4K = ((long)MAXBITMAPINDEX + 1) * BITMAP_PAYLOAD_4K * BITMAP_PAYLOAD_4K * 32;
        public const long MAXDISKSIZE = MAXDISKSIZE4K;


        /* max length of filename, diskname and comment
 * FNSIZE is 108 for compatibilty. Used for searching
 * files.
 */
        public const int FNSIZE = 108;

        public const int PATHSIZE = 256;

        //public const int  FILENAMESIZE (g->fnsize)
        public const int DNSIZE = 32;

        public const int CMSIZE = 80;
        //public const int  MAX_ENTRYSIZE (sizeof(struct direntry) + FNSIZE + CMSIZE + 34)

/* disk id 'PFS\1'  */
//#ifdef BETAVERSION
//#define ID_PFS_DISK		(0x42455441L)	/*	'BETA'	*/
//#else
        public const int ID_PFS_DISK = 0x50465301; /*  'PFS\1' */

//#endif
        public const int ID_BUSY = 0x42555359; /*	'BUSY'  */

        public const int ID_MUAF_DISK = 0x6d754146; /*	'muAF'	*/
        public const int ID_MUPFS_DISK = 0x6d755046; /*	'muPF'	*/
        public const int ID_AFS_DISK = 0x41465301; /*	'AFS\1' */
        public const int ID_PFS2_DISK = 0x50465302; /*	'PFS\2'	*/
        public const int ID_AFS_USER_TEST = 0x41465355; /*	'AFSU'	*/

        /// <summary>
        /// dir block id (DB)
        /// </summary>
        public const ushort DBLKID = 0x4442;
        
        /// <summary>
        /// anode block id (AB)
        /// </summary>
        public const ushort ABLKID = 0x4142;
        
        /// <summary>
        /// index block id (IB)
        /// </summary>
        public const ushort IBLKID = 0x4942;
        public const ushort BMBLKID = 0x424D;
        public const ushort BMIBLKID = 0x4D49;
        
        /// <summary>
        /// deldir block id (DD)
        /// </summary>
        public const ushort DELDIRID = 0x4444;
        public const ushort EXTENSIONID = 0x4558; // EX
        public const ushort SBLKID = 0x5342; // 'SB

        /* ID stands for InfoData Disk states */
        public const int ID_WRITE_PROTECTED = 80; /* Disk is write protected */
        public const int ID_VALIDATING = 81; /* Disk is currently being validated */
        public const int ID_VALIDATED = 82; /* Disk is consistent and writeable */

        /* Cache hashing table mask values for dir and anode */
        public const int HASHM_DIR = 0x1f;
        public const int HASHM_ANODE = 0x7;

        /* predefined anodes */
        public const int ANODE_EOF = 0;
        public const int ANODE_RESERVED_1 = 1; // not used by MODE_BIG
        public const int ANODE_RESERVED_2 = 2; // not used by MODE_BIG
        public const int ANODE_RESERVED_3 = 3; // not used by MODE_BIG
        public const int ANODE_BADBLOCKS = 4; // not used yet
        public const int ANODE_ROOTDIR = 5;
        public const int ANODE_USERFIRST = 6;

        public const char DELENTRY_SEP = '@';
        public const int DELENTRY_PROT = 0x0005;
        public const int DELENTRY_PROT_AND_MASK = 0xaa0f;
        public const int DELENTRY_PROT_OR_MASK = 0x0005;

        /* maximum number of entries per block, max deldirblock seqnr */
        public const int DELENTRIES_PER_BLOCK = 31;
        public const int MAXDELDIR = 31;

        public const int DATACACHELEN = 32;
        public const int DATACACHEMASK = DATACACHELEN - 1;
        
/* cache grootte */
            public const int RTBF_CACHE_SIZE = 512;
            public const int TBF_CACHE_SIZE = 256;

/* update thresholds */
            public const int RTBF_THRESHOLD = 256;
            public const int RTBF_CHECK_TH = 128;
            public const int RTBF_POSTPONED_TH = 48;
            public const int TBF_THRESHOLD = 252;
            public const int RESFREE_THRESHOLD = 10;

/* indices in tobefreed array */
            public const int TBF_BLOCKNR = 0;
            public const int TBF_SIZE = 1;

/* buffer for AllocReservedBlockSave */
            public const int RESERVED_BUFFER = 10;
    }
}