namespace HstWbInstaller.Core.IO.FastFileSystem
{
    public class FileExtBlock
    {
        // struct bFileExtBlock {
        // 000	int32_t	type;		/* == 0x10 */
        // 004	int32_t	headerKey;
        // 008	int32_t	highSeq;
        // 00c	int32_t	dataSize;	/* == 0 */
        // 010	int32_t	firstData;	/* == 0 */
        // 014	ULONG	checkSum;
        // 018	int32_t	dataBlocks[MAX_DATABLK];
        //             int32_t	r[45];
        //             int32_t	info;		/* == 0 */
        //             int32_t	nextSameHash;	/* == 0 */
        // 1f4	int32_t	parent;		/* header block */
        // 1f8	int32_t	extension;	/* next header extension block */
        // 1fc	int32_t	secType;	/* -3 */	
        // };

        public byte[] BlockBytes { get; set; }

        public int type;		/* == 0x10 */
        public int headerKey;
        public int highSeq;
        public int dataSize;	/* == 0 */
        public int firstData;	/* == 0 */
        public uint checkSum;
        public int[] dataBlocks;
        public int[] r;
        public int info;		/* == 0 */
        public int nextSameHash;	/* == 0 */
        public int parent;		/* header block */
        public int extension;	/* next header extension block */
        public int secType;	/* -3 */

        public FileExtBlock()
        {
            dataBlocks = new int[Constants.MAX_DATABLK];
            r = new int[45];
        }
    }
}