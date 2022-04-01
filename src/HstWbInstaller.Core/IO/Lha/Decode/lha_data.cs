namespace HstWbInstaller.Core.IO.Lha.Decode
{
    using System.IO;

    public class lha_data
    {
        public Stream stream;
        public bool decompress_init;
        public lzh_stream strm;
        public long entry_bytes_remaining;
        public string method;
        public bool end_of_entry;
        public long entry_unconsumed;
        public bool entry_is_compressed;
        public long entry_offset;
    }
}