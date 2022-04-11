namespace HstWbInstaller.Core.IO.Pfs3
{
    public class canode
    {
        // Cached Allocation NODE
        public uint clustersize;	// number of blocks in a cluster
        public uint blocknr;		// the block number
        public uint next;			// next anode (anodenummer), 0 = eof
        public uint nr;			// the anodenr
    }
}