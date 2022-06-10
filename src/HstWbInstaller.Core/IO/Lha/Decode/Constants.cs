namespace HstWbInstaller.Core.IO.Lha.Decode
{
    public static class Constants
    {
        public const int HTBL_BITS = 10;
        public const byte UCHAR_MAX = (1 << 8) - 1;
        public const int MAXMATCH = 256; /* Maximum match length. */
        public const int MINMATCH = 3; /* Minimum match length. */

        /* Literal table size. */
        public const int LT_BITLEN_SIZE = (UCHAR_MAX + 1 + MAXMATCH - MINMATCH + 1);

        /* Position table size.
        * Note: this used for both position table and pre literal table.*/
        public const int PT_BITLEN_SIZE = 3 + 16;
        
        public const int ARCHIVE_EOF = 1; /* Found end of archive. */
        public const int ARCHIVE_OK = 0; /* Operation was successful. */
        public const int ARCHIVE_RETRY = -10; /* Retry might succeed. */

        public const int ARCHIVE_WARN = -20; /* Partial success. */

        /* For example, if write_header "fails", then you can't push data. */
        public const int ARCHIVE_FAILED = -25; /* Current operation cannot complete. */

        /* But if write_header is "fatal," then this archive is dead and useless. */
        public const int ARCHIVE_FATAL = -30; /* No more operations are possible. */
        
    }
}