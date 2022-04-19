namespace HstWbInstaller.Core.IO.Pfs3
{
    public static class SizeOf
    {
        public const int UWORD = 2;
        public const int ULONG = 4;
        public const int LONG = 4;

        public const int INDEXBLOCK_T = 2 * UWORD + 2 * ULONG;
        public const int ANODEBLOCK_T = 2 * UWORD + 3 * ULONG;
        public const int ANODE_T = 3 * ULONG;

        public static class DirBlock
        {
            public static int Entries(globaldata g) => g.RootBlock.ReservedBlksize - UWORD * 2 - ULONG * 3;
        }
        
        public static class DelDirBlock
        {
            public const int Entry = SizeOf.ULONG * 2 + SizeOf.UWORD * 3 + 16 + SizeOf.UWORD;

            public static int Entries(globaldata g) => (g.RootBlock.ReservedBlksize - SizeOf.UWORD * 2 - SizeOf.ULONG * 2 - SizeOf.UWORD * 4 -
                                                        SizeOf.ULONG - SizeOf.UWORD * 3) / Entry;
        }
    }
}