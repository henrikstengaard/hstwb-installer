namespace HstWbInstaller.Core.IO.Lha.Decode
{
    public class lzh_br
    {
        // bit stream reader
        public const byte uint64_t_size = 8;

        public const int CACHE_BITS = 8 * uint64_t_size;

        /* Cache buffer. */
        public ulong cache_buffer;

        /* Indicates how many bits avail in cache_buffer. */
        public int cache_avail;
    }
}