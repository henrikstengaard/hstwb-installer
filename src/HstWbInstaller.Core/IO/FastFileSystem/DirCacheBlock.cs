namespace HstWbInstaller.Core.IO.FastFileSystem
{
    public class DirCacheBlock
    {
//         struct bDirCacheBlock {
// /*000*/	int32_t	type;		/* == 33 */
// /*004*/	int32_t	headerKey;
// /*008*/	int32_t	parent;
// /*00c*/	int32_t	recordsNb;
// /*010*/	int32_t	nextDirC;
// /*014*/	ULONG	checkSum;
// /*018*/	uint8_t records[488];
//         };
        public byte[] BlockBytes { get; set; }

        public int Type { get; set; }
        public int HeaderKey { get; set; }
        public int Parent { get; set; }
        public int RecordsNb { get; set; }
        public int NextDirC { get; set; }
        public int CheckSum { get; set; }
        public byte[] Records { get; set; }

        public DirCacheBlock()
        {
            Records = new byte[488];
        }
    }
}