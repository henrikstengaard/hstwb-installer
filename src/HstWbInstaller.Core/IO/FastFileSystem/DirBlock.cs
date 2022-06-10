namespace HstWbInstaller.Core.IO.FastFileSystem
{
    using System;

    public class DirBlock : EntryBlock
    {
//         struct bDirBlock {
// /*000*/	int32_t	type;		/* == 2 */
// /*004*/	int32_t	headerKey;
// /*008*/	int32_t	highSeq;	/* == 0 */
// /*00c*/	int32_t	hashTableSize;	/* == 0 */
//             int32_t	r1;		/* == 0 */
// /*014*/	ULONG	checkSum;
// /*018*/	int32_t	hashTable[HT_SIZE];		/* hash table */
//             int32_t	r2[2];
// /*140*/	int32_t	access;
//             int32_t	r4;		/* == 0 */
// /*148*/	char	commLen;
// /*149*/	char	comment[MAXCMMTLEN+1];
//             char	r5[91-(MAXCMMTLEN+1)];
// /*1a4*/	int32_t	days;		/* last access */
// /*1a8*/	int32_t	mins;
// /*1ac*/	int32_t	ticks;
// /*1b0*/	char	nameLen;
// /*1b1*/	char 	dirName[MAXNAMELEN+1];
//             int32_t	r6;
// /*1d4*/	int32_t	real;		/* ==0 */
// /*1d8*/	int32_t	nextLink;	/* link list */
//             int32_t	r7[5];
// /*1f0*/	int32_t	nextSameHash;
// /*1f4*/	int32_t	parent;
// /*1f8*/	int32_t	extension;		/* FFS : first directory cache */
// /*1fc*/	int32_t	secType;	/* == 2 */
//         };  
        // public byte[] BlockBytes { get; set; }
        //
        // public int Type { get; set; }
        // public int HeaderKey { get; set; }
        // public int HighSeq { get; set; }
        // public int HashTableSize { get; set; }
        // public uint CheckSum;
        //
        // public int[] HashTable { get; set; }
        // public int[] DataBlocks { get => HashTable; set => HashTable = value; }
        //
        // public int Access { get; set; }
        // public string Comment { get; set; }
        // public DateTime Date { get; set; }
        // public string Name { get; set; }
        // public int RealEntry { get; set; }
        // public int NextLink { get; set; }
        // public int NextSameHash { get; set; }
        // public int Parent { get; set; }
        // public int Extension { get; set; }
        // public int SecType { get; set; }
    }
}