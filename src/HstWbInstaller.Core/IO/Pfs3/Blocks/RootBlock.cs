namespace HstWbInstaller.Core.IO.Pfs3.Blocks
{
    using System;

    public class RootBlock
    {
        // pfs3src/pfs/format.c
        // pfs3src/pfs/blocks.h
        /*
typedef struct rootblock
{
    LONG disktype;  0
    ULONG options;          /* bit 0 is harddisk mode      4     
        ULONG datestamp;        /* current datestamp  8
        UWORD creationday;      /* days since Jan. 1, 1978 (like ADOS; WORD instead of LONG)  12 
        UWORD creationminute;   /* minutes past modnight            14
        UWORD creationtick;     /* ticks past minute                16
        UWORD protection;       /* protection bits (ala ADOS)       18
        UBYTE diskname[32];     /* disk label (pascal string)       20
        ULONG lastreserved;     /* reserved area. blocknumbers      52
        ULONG firstreserved;                                        56
        ULONG reserved_free;    /* number of reserved blocks (blksize blocks) free  60  
        UWORD blksize;          /* size of reserved blocks in bytes 
        UWORD rblkcluster;      /* number of blocks in rootblock, including bitmap  
        ULONG blocksfree;       /* blocks free                      
        ULONG alwaysfree;       /* minimum number of blocks free    
        ULONG roving_ptr;       /* current LONG bitmapfield nr for allocation       
        ULONG deldir;           /* deldir location (<= 17.8)        
        ULONG disksize;         /* disksize in sectors              
        ULONG extension;        /* rootblock extension (16.4)       
        ULONG not_used;
        union
        {
            UWORD anodeblocks[208];         /* SMALL: 200*84 = 16800 anodes 
            struct
            {
                ULONG bitmapindex[5];       /* 5 bitmap indexblocks with 253 bitmap blocks each 
                ULONG indexblocks[99];      /* 99 index blocks with 253 anode blocks each       
            } small;
            struct 
            {
                ULONG bitmapindex[104];		/* 104 bitmap indexblocks = max 104 G 
            } large;
        };
    } rootblock_t;
    */
        [Flags]
        public enum DiskOptionsEnum : int
        {
            /* disk options */
            MODE_HARDDISK = 1,
            MODE_SPLITTED_ANODES = 2,
            MODE_DIR_EXTENSION = 4,
            MODE_DELDIR = 8,
            MODE_SIZEFIELD = 16,

            // rootblock extension
            MODE_EXTENSION = 32,

            // if enabled the datestamp was on at format time (!)
            MODE_DATESTAMP = 64,
            MODE_SUPERINDEX = 128,
            MODE_SUPERDELDIR = 256,
            MODE_EXTROVING = 512,
            MODE_LONGFN = 1024,
            MODE_LARGEFILE = 2048
        }

        public byte[] BlockBytes { get; set; }

        /// <summary>
        /// bit 0 is harddisk mode
        /// </summary>
        public int DiskType { get; set; }

        /// <summary>
        /// bit 0 is harddisk mode
        /// </summary>
        public DiskOptionsEnum Options { get; set; }

        /// <summary>
        /// current datestamp
        /// </summary>
        public uint Datestamp { get; set; }

        /// <summary>
        /// Creation date
        /// </summary>
        public DateTime CreationDate { get; set; }

        /// <summary>
        /// protection bits (ala ADOS)
        /// </summary>
        public ushort Protection { get; set; }

        /// <summary>
        /// disk label (pascal string)
        /// </summary>
        public string DiskName { get; set; }

        /// <summary>
        /// reserved area. blocknumbers at end of partition
        /// </summary>
        public uint LastReserved { get; set; }

        /// <summary>
        /// reserved area. blocknumbers at beginning of partition
        /// </summary>
        public uint FirstReserved { get; set; }

        /// <summary>
        /// number of reserved blocks (blksize blocks) free
        /// </summary>
        public uint ReservedFree { get; set; }

        /// <summary>
        /// size of reserved blocks in bytes
        /// </summary>
        public ushort ReservedBlksize { get; set; }

        /// <summary>
        /// number of blocks in rootblock, including bitmap
        /// </summary>
        public ushort RblkCluster { get; set; }

        /// <summary>
        /// blocks free
        /// </summary>
        public uint BlocksFree { get; set; }

        /// <summary>
        /// minimum number of blocks free
        /// </summary>
        public uint AlwaysFree { get; set; }

        /// <summary>
        /// current LONG bitmapfield nr for allocation
        /// </summary>
        public uint RovingPtr { get; set; }

        /// <summary>
        /// deldir location (<= 17.8)
        /// </summary>
        public uint DelDir { get; set; }

        /// <summary>
        /// disksize in sectors
        /// </summary>
        public uint DiskSize { get; set; }

        /// <summary>
        /// rootblock extension (16.4)
        /// </summary>
        public uint Extension { get; set; }
        
        /* Longs per bitmapblock */
        // #define LONGS_PER_BMB ((g->rootblock->reserved_blksize/4)-3) // 253/509/1021
        public int LongsPerBmb => (ReservedBlksize / 4) - 3; // 253/509/1021

        public RootBlockIndex idx;
        public BitmapBlock ReservedBitmapBlock { get; set; }

        public RootBlock()
        {
            idx = new RootBlockIndex();
        }
    }
}