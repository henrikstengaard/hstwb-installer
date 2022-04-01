namespace HstWbInstaller.Core.IO.Lha.Decode
{
    public class lzh_dec
    {
        // https://github.com/libarchive/libarchive/blob/master/libarchive/archive_read_support_format_lha.c#L66

        /* Decoding status. */
        public int state;

        /*
         * Window to see last 8Ki(lh5),32Ki(lh6),64Ki(lh7) bytes of decoded
         * data.
         */
        public uint w_size;

        public uint w_mask;

        /* Window buffer, which is a loop buffer. */
        public byte[] w_buff;

        /* The insert position to the window. */
        public int w_pos;

        /* The position where we can copy decoded code from the window. */
        public int copy_pos;

        /* The length how many bytes we can copy decoded code from
         * the window. */
        public int copy_len;
        
        public lzh_br br;

        public huffman lt;
        public huffman pt;

        public int blocks_avail;
        public int pos_pt_len_size;
        public int pos_pt_len_bits;
        public int literal_pt_len_size;
        public int literal_pt_len_bits;
        public bool reading_position;
        public int loop;
        public int error;

        public lzh_dec()
        {
            br = new lzh_br();
            lt = new huffman();
            pt = new huffman();
        }
    }
}