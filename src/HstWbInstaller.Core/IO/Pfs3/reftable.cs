namespace HstWbInstaller.Core.IO.Pfs3
{
    public class reftable
    {
        public uint blocknr;          /* blocknr of cached block; 0 = empty slot */
        public bool dirty;            /* dirty flag (TRUE/FALSE) */
        public byte pad;
    };
}