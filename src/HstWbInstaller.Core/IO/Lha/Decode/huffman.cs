namespace HstWbInstaller.Core.IO.Lha.Decode
{
    public class huffman
    {
        public const int FreqSize = 17;
        
        public int len_size;
        public int len_avail;
        public int len_bits;
        public int[] freq;
        public byte[] bitlen;

        /*
         * Use a index table. It's faster than searching a huffman
         * coding tree, which is a binary tree. But a use of a large
         * index table causes L1 cache read miss many times.
         */

        public int max_bits;
        public int shift_bits;
        public int tbl_bits;
        public int tree_used;

        public int tree_avail;

        /* Direct access table. */
        public ushort[] tbl;

        public htree_t[] tree;

        public huffman()
        {
            freq = new int[FreqSize];
        }
    }
}