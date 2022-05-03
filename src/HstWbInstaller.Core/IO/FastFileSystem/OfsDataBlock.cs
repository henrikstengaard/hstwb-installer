namespace HstWbInstaller.Core.IO.FastFileSystem
{
    public class OfsDataBlock : IDataBlock
    {
        // 000	int32_t	type;		/* == 8 */
        // 004	int32_t	headerKey;	/* pointer to file_hdr block */
        // 008	int32_t	seqNum;	/* file data block number */
        // 00c	int32_t	dataSize;	/* <= 0x1e8 */
        // 010	int32_t	nextData;	/* next data block */
        // 014	ULONG	checkSum;
        // 018	UCHAR	data[488];
        // 200

        public int Type { get; set; }
        public int HeaderKey { get; set; }
        public int SeqNum { get; set; }
        public int DataSize { get; set; }
        public int NextData { get; set; }
        public uint CheckSum { get; set; }
        public byte[] BlockBytes { get; set; }
        public byte[] Data { get; set; }

        public OfsDataBlock()
        {
            Data = new byte[488];
        }
    }
}