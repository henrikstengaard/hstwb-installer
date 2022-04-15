namespace HstWbInstaller.Core.IO.Pfs3
{
    public class anode
    {
        public uint clustersize;
        public uint blocknr;
        public uint next;

        public const int Size = SizeOf.ULONG * 3;
    }
}