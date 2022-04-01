namespace HstWbInstaller.Core.IO.Lha.Decode
{
    using System;

    public class lzh_stream
    {
        // pointer to next_in
        public int p_next_in;
        
        public byte[] next_in;
        public int avail_in;
        public long total_in;
        public byte[] ref_ptr;
        public int avail_out;
        public long total_out;
        public lzh_dec ds;

        public lzh_stream()
        {
            ds = new lzh_dec();
            next_in = Array.Empty<byte>();
        }
    }
}