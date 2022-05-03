namespace HstWbInstaller.Core.IO.FastFileSystem
{
    using System;

    public class EntryBlock : IEntryBlock
    {
        /*
        struct bEntryBlock {
        // 000	int32_t	type;		// T_HEADER == 2
        // 004	int32_t	headerKey;	// current block number 
                    int32_t	r1[3];
        // 014	uint32_t	checkSum;
        // 018	int32_t	hashTable[HT_SIZE];
                    int32_t	r2[2];
        // 140	int32_t	access;	// bit0=del, 1=modif, 2=write, 3=read
        // 144	int32_t	byteSize;
        // 148	char	commLen;
        // 149	char	comment[MAXCMMTLEN+1];
                    char	r3[91-(MAXCMMTLEN+1)];
        // 1a4	int32_t	days;
        // 1a8	int32_t	mins;
        // 1ac	int32_t	ticks;
        // 1b0	char	nameLen;
        // 1b1	char	name[MAXNAMELEN+1];
                    int32_t	r4;
        // 1d4	int32_t	realEntry;
        // 1d8	int32_t	nextLink;
                    int32_t	r5[5];
        // 1f0	int32_t	nextSameHash;
        // 1f4	int32_t	parent;
        // 1f8	int32_t	extension;
        // 1fc	int32_t	secType;
        };
         */
        public byte[] BlockBytes { get; set; }
        public int Type { get; set; }
        public int HeaderKey { get; set; }
        public uint Checksum { get; set; }
        public int[] HashTable { get; set; }
        
        public int[] DataBlocks
        {
            get => HashTable;
            set => HashTable = value;
        }
        
        public int Access { get; set; }
        public int ByteSize { get; set; }
        public string Comment { get; set; }
        public DateTime Date { get; set; }
        public string Name { get; set; }
        public int RealEntry { get; set; }
        public int NextLink { get; set; }
        public int NextSameHash { get; set; }
        public int Parent { get; set; }
        public int Extension { get; set; }
        public int SecType { get; set; }
    }
}