namespace HstWbInstaller.Core.IO.Pfs3.Blocks
{
    public class RootBlockIndex
    {
        public class Small
        {
            /*
            struct
            {
                ULONG bitmapindex[Constants.MAXSMALLBITMAPINDEX + 1];       // 5 bitmap indexblocks with 253 bitmap blocks each
                ULONG indexblocks[Constants.MAXSMALLINDEXNR + 1];      // 99 index blocks with 253 (more if reserved blocks > 1K) anode blocks each      
            } small;
             */
            public uint[] bitmapindex;
            public uint[] indexblocks;

            public Small()
            {
                bitmapindex = new uint[Constants.MAXSMALLBITMAPINDEX + 1];
                indexblocks = new uint[Constants.MAXSMALLINDEXNR + 1];
            }
        }

        public class Large
        {
            /*
            struct 
            {
                ULONG bitmapindex[Constants.MAXBITMAPINDEX + 1];		// 104 bitmap indexblocks = max 104 G
            } large;
             */
            public uint[] bitmapindex;

            public Large()
            {
                bitmapindex = new uint[Constants.MAXSMALLINDEXNR + 1];
            }
        }
        
        public Small small;
        public Large large;

        public RootBlockIndex()
        {
            small = new Small();
            large = new Large();
        }
    }
}