namespace HstWbInstaller.Core.IO.Pfs3
{
    using Blocks;

    public class allocation_data_s
    {
        public uint clean_blocksfree;             /* number of blocks directly allocatable            */
        public uint alloc_available;              /* cleanblocksfree + blockstobefreed - alwaysfree   */
        public uint longsperbmb;                  /* longwords per bitmapblock                        */
        public uint no_bmb;                       /* number of bitmap blocks                          */
        public uint bitmapstart;                  /* blocknr at which bitmap starts                   */
        public uint[][] tobefreed; /* tobefreed array                                  */
        public uint tobefreed_index;
        public uint tbf_resneed;                  /* max reserved blks needed for tbf cache           */
        public BitmapBlock res_bitmap;     /* reserved block bitmap pointer                    */
        public uint res_roving;                   /* reserved roving pointer (0 at startup)           */
        public uint rovingbit;                    /* bitnumber (within LW) of main roving pointer     */
        public uint numreserved;                  /* total # reserved blocks (== lastreserved+1)      */
        public uint[] reservedtobefreed;           /* tbf cache for flush reserved blocks  */
        public uint rtbf_size;                    /* size of the allocated cache */
        public uint rtbf_index;                   /* current index in reserved tobefreed cache        */
        public bool res_alert;                     /* TRUE if low on available reserved blocks         */

        public allocation_data_s()
        {
            tobefreed = new uint[Constants.TBF_CACHE_SIZE][];
            for (var i = 0; i < Constants.TBF_CACHE_SIZE; i++)
            {
                tobefreed[i] = new uint[2];
            }
        }
    }
}