namespace HstWbInstaller.Core.IO.Lha.Decode
{
    public static class LzhBitStreamReader
    {
        // Check that the cache buffer has enough bits.
        public static bool lzh_br_has(lzh_br br, int n) => br.cache_avail >= n;
        
        /* Get compressed data by bit. */
        public static int lzh_br_bits(lzh_br br, int n)
        {
            // (((uint16_t)((br)->cache_buffer >> ((br)->cache_avail - (n)))) & cache_masks[n])
            return (ushort)(br.cache_buffer >> (br.cache_avail - n)) & cache_masks[n];
        }

        public static int lzh_br_bits_forced(lzh_br br, int n)
        {
            // (((uint16_t)((br)->cache_buffer << ((n) - (br)->cache_avail))) & cache_masks[n])
            return (ushort)(br.cache_buffer << (n - br.cache_avail)) & cache_masks[n];
        }

        /* Notify how many bits we consumed. */
        public static void lzh_br_consume(lzh_br br, int n) => br.cache_avail -= n;

        /* Read ahead to make sure the cache buffer has enough compressed data we
         * will use.
         *  True  : completed, there is enough data in the cache buffer.
         *  False : we met that strm->next_in is empty, we have to get following
         *          bytes. */
        public static bool lzh_br_read_ahead_0(lzh_stream strm, lzh_br br, ushort n)
        {
            // (lzh_br_has(br, (n)) || lzh_br_fillup(strm, br))
            return lzh_br_has(br, n) || lzh_br_fillup(strm, br);
        }

        /*  True  : the cache buffer has some bits as much as we need.
         *  False : there are no enough bits in the cache buffer to be used,
         *          we have to get following bytes if we could. */
        public static bool lzh_br_read_ahead(lzh_stream strm, lzh_br br, ushort n)
        {
            // (lzh_br_read_ahead_0((strm), (br), (n)) || lzh_br_has((br), (n)))
            return lzh_br_read_ahead_0(strm, br, n) || lzh_br_has(br, n);
        }

        public static readonly ushort[] cache_masks =
        {
            0x0000, 0x0001, 0x0003, 0x0007,
            0x000F, 0x001F, 0x003F, 0x007F,
            0x00FF, 0x01FF, 0x03FF, 0x07FF,
            0x0FFF, 0x1FFF, 0x3FFF, 0x7FFF,
            0xFFFF, 0xFFFF, 0xFFFF, 0xFFFF
        };

        /*
         * Shift away used bits in the cache data and fill it up with following bits.
         * Call this when cache buffer does not have enough bits you need.
         *
         * Returns 1 if the cache buffer is full.
         * Returns 0 if the cache buffer is not full; input buffer is empty.
         */
        public static bool lzh_br_fillup(lzh_stream strm, lzh_br br)
        {
            var n = lzh_br.CACHE_BITS - br.cache_avail;

            for (;;)
            {
                var x = n >> 3;
                if (strm.avail_in >= x)
                {
                    switch (x)
                    {
                        case 8:
                            br.cache_buffer =
                                ((ulong)strm.next_in[strm.p_next_in + 0]) << 56 |
                                ((ulong)strm.next_in[strm.p_next_in + 1]) << 48 |
                                ((ulong)strm.next_in[strm.p_next_in + 2]) << 40 |
                                ((ulong)strm.next_in[strm.p_next_in + 3]) << 32 |
                                ((ulong)strm.next_in[strm.p_next_in + 4]) << 24 |
                                ((ulong)strm.next_in[strm.p_next_in + 5]) << 16 |
                                ((ulong)strm.next_in[strm.p_next_in + 6]) << 8 |
                                strm.next_in[7];
                            strm.p_next_in += 8;
                            strm.avail_in -= 8;
                            br.cache_avail += 8 * 8;
                            return true;
                        case 7:
                            br.cache_buffer =
                                (br.cache_buffer << 56) |
                                ((ulong)strm.next_in[strm.p_next_in + 0]) << 48 |
                                ((ulong)strm.next_in[strm.p_next_in + 1]) << 40 |
                                ((ulong)strm.next_in[strm.p_next_in + 2]) << 32 |
                                ((ulong)strm.next_in[strm.p_next_in + 3]) << 24 |
                                ((ulong)strm.next_in[strm.p_next_in + 4]) << 16 |
                                ((ulong)strm.next_in[strm.p_next_in + 5]) << 8 |
                                (ulong)strm.next_in[strm.p_next_in + 6];
                            strm.p_next_in += 7;
                            strm.avail_in -= 7;
                            br.cache_avail += 7 * 8;
                            return true;
                        case 6:
                            br.cache_buffer =
                                (br.cache_buffer << 48) |
                                ((ulong)strm.next_in[strm.p_next_in + 0]) << 40 |
                                ((ulong)strm.next_in[strm.p_next_in + 1]) << 32 |
                                ((ulong)strm.next_in[strm.p_next_in + 2]) << 24 |
                                ((ulong)strm.next_in[strm.p_next_in + 3]) << 16 |
                                ((ulong)strm.next_in[strm.p_next_in + 4]) << 8 |
                                (ulong)strm.next_in[strm.p_next_in + 5];
                            strm.p_next_in += 6;
                            strm.avail_in -= 6;
                            br.cache_avail += 6 * 8;
                            return true;
                        case 0:
                            /* We have enough compressed data in
                             * the cache buffer.*/
                            return true;
                    }
                }

                if (strm.avail_in == 0)
                {
                    /* There is not enough compressed data to fill up the
                     * cache buffer. */
                    return false;
                }

                br.cache_buffer = (br.cache_buffer << 8) | strm.next_in[strm.p_next_in++];
                strm.avail_in--;
                br.cache_avail += 8;
                n -= 8;
            }
        }
    }
}