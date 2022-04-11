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
    }
}