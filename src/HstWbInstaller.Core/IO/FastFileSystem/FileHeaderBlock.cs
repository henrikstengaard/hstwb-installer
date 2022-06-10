namespace HstWbInstaller.Core.IO.FastFileSystem
{
    public class FileHeaderBlock : EntryBlock
    {
// struct bFileHeaderBlock {
// 000	int32_t	type;		/* == 2 */
// 004	int32_t	headerKey;	/* current block number */
// 008	int32_t	highSeq;	/* number of data block in this hdr block */
// 00c	int32_t	dataSize;	/* == 0 */
// 010	int32_t	firstData;
// 014	ULONG	checkSum;
// 018	int32_t	dataBlocks[MAX_DATABLK];
// 138	int32_t	r1;
// 13c	int32_t	r2;
// 140	int32_t	access;	/* bit0=del, 1=modif, 2=write, 3=read */
// 144	uint32_t	byteSize;
//148	char	commLen;
// 149	char	comment[MAXCMMTLEN+1];
//        char	r3[91-(MAXCMMTLEN+1)];
// 1a4	int32_t	days;
// 1a8	int32_t	mins;
// 1ac	int32_t	ticks;
// 1b0	char	nameLen;
// 1b1	char	fileName[MAXNAMELEN+1];
//        int32_t	r4;
// 1d4	int32_t	real;		/* unused == 0 */
// 1d8	int32_t	nextLink;	/* link chain */
//        int32_t	r5[5];
// 1f0	int32_t	nextSameHash;	/* next entry with sane hash */
// 1f4	int32_t	parent;		/* parent directory */
// 1f8	int32_t	extension;	/* pointer to extension block */
// 1fc	int32_t	secType;	// == -3 */
// }

        // public int Type { get; set; } /* == 2 */
        // public int HeaderKey { get; set; } /* current block number */
        // public int highSeq { get; set; } /* number of data block in this hdr block */
        // public int dataSize { get; set; } /* == 0 */
        // public int firstData;
        // public uint checkSum;
        // public int[] DataBlocks { get; set; }
        //
        // public int[] HashTable
        // {
        //     get => DataBlocks;
        //     set => DataBlocks = value;
        // }
        //
        // public int access; /* bit0=del, 1=modif, 2=write, 3=read */
        // public uint byteSize;
        // public string comment;
        // public DateTime Date;
        // public string fileName;
        // public int real; /* unused == 0 */
        // public int nextLink; /* link chain */
        // public int nextSameHash; /* next entry with sane hash */
        // public int parent; /* parent directory */
        // public int Extension { get; set; } /* pointer to extension block */
        // public int SecType { get; set; } /* == -3 */
        //
        // public FileHeaderBlock()
        // {
        //     DataBlocks = new int[Constants.MAX_DATABLK];
        // }
        //
        // public byte[] BlockBytes { get; set; }
    };
}