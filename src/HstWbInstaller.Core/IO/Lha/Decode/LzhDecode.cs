namespace HstWbInstaller.Core.IO.Lha.Decode
{
    using System;

    public static class LzhDecode
    {
/*
 * Initialize LZHUF decoder.
 *
 * Returns ARCHIVE_OK if initialization was successful.
 * Returns ARCHIVE_FAILED if method is unsupported.
 * Returns ARCHIVE_FATAL if initialization failed; memory allocation
 * error occurred.
 */
        public static int lzh_decode_init(lzh_stream strm, string method)
        {
            int w_bits, w_size;

            if (strm.ds == null)
            {
                strm.ds = new lzh_dec();
            }
            var ds = strm.ds;
            ds.error = Constants.ARCHIVE_FAILED;
            if (string.IsNullOrEmpty(method) || method[1] != 'l' || method[2] != 'h')
                return Constants.ARCHIVE_FAILED;
            switch (method[3]) {
                case '5':
                    w_bits = 13;/* 8KiB for window */
                    break;
                case '6':
                    w_bits = 15;/* 32KiB for window */
                    break;
                case '7':
                    w_bits = 16;/* 64KiB for window */
                    break;
                default:
                    return Constants.ARCHIVE_FAILED;/* Not supported. */
            }
            ds.error = Constants.ARCHIVE_FATAL;
            /* Expand a window size up to 128 KiB for decompressing process
             * performance whatever its original window size is. */
            ds.w_size = 1U << 17;
            ds.w_mask = ds.w_size -1;
            if (ds.w_buff == null) {
                ds.w_buff = new byte[ds.w_size];
            }
            w_size = (int)(1U << w_bits);
            //memset(ds->w_buff + ds->w_size - w_size, 0x20, w_size);
            for (var x = 0; x < w_size; x++)
            {
                ds.w_buff[ds.w_size - w_size + x] = 0x20;
            }
            ds.w_pos = 0;
            ds.state = 0;
            ds.pos_pt_len_size = w_bits + 1;
            ds.pos_pt_len_bits = (w_bits == 15 || w_bits == 16)? 5: 4;
            ds.literal_pt_len_size = Constants.PT_BITLEN_SIZE;
            ds.literal_pt_len_bits = 5;
            ds.br.cache_buffer = 0;
            ds.br.cache_avail = 0;

            LzhHuffman.lzh_huffman_init(ds.lt, Constants.LT_BITLEN_SIZE, 16);
            ds.lt.len_bits = 9;
            LzhHuffman.lzh_huffman_init(ds.pt, Constants.PT_BITLEN_SIZE, 16);
            ds.error = 0;

            return Constants.ARCHIVE_OK;
        }
            
        /*
         * Decode LZHUF.
         *
         * 1. Returns ARCHIVE_OK if output buffer or input buffer are empty.
         *    Please set available buffer and call this function again.
         * 2. Returns ARCHIVE_EOF if decompression has been completed.
         * 3. Returns ARCHIVE_FAILED if an error occurred; compressed data
         *    is broken or you do not set 'last' flag properly.
         * 4. 'last' flag is very important, you must set 1 to the flag if there
         *    is no input data. The lha compressed data format does not provide how
         *    to know the compressed data is really finished.
         *    Note: lha command utility check if the total size of output bytes is
         *    reached the uncompressed size recorded in its header. it does not mind
         *    that the decoding process is properly finished.
         *    GNU ZIP can decompress another compressed file made by SCO LZH compress.
         *    it handles EOF as null to fill read buffer with zero until the decoding
         *    process meet 2 bytes of zeros at reading a size of a next chunk, so the
         *    zeros are treated as the mark of the end of the data although the zeros
         *    is dummy, not the file data.
         */
        private const int ST_RD_BLOCK = 0;
        private const int ST_RD_PT_1 = 1;
        private const int ST_RD_PT_2 = 2;
        private const int ST_RD_PT_3 = 3;
        private const int ST_RD_PT_4 = 4;
        private const int ST_RD_LITERAL_1 = 5;
        private const int ST_RD_LITERAL_2 = 6;
        private const int ST_RD_LITERAL_3 = 7;
        private const int ST_RD_POS_DATA_1 = 8;
        private const int ST_GET_LITERAL = 9;
        private const int ST_GET_POS_1 = 10;
        private const int ST_GET_POS_2 = 11;
        private const int ST_COPY_DATA = 12;

        public static int lzh_decode(lzh_stream strm, bool last)
        {
            var ds = strm.ds;
            int r;

            if (ds.error != 0)
                return ds.error;

            var avail_in = strm.avail_in;
            do
            {
                if (ds.state < ST_GET_LITERAL)
                    r = lzh_read_blocks(strm, last);
                else
                    r = lzh_decode_blocks(strm, last);
            } while (r == 100);

            strm.total_in += avail_in - strm.avail_in;
            return r;
        }

        public static void lzh_emit_window(lzh_stream strm, int s)
        {
            strm.ref_ptr = strm.ds.w_buff;
            strm.avail_out = s;
            strm.total_out += s;
        }

        public static int lzh_read_blocks(lzh_stream strm, bool last)
        {
            var ds = strm.ds;
            var br = ds.br;
            int c = 0, i;
            int rbits;

            for (;;)
            {
                var fallThrough = false;
                if (ds.state == ST_RD_BLOCK)
                {
                    /*
                     * Read a block number indicates how many blocks
                     * we will handle. The block is composed of a
                     * literal and a match, sometimes a literal only
                     * in particular, there are no reference data at
                     * the beginning of the decompression.
                     */
                    if (!LzhBitStreamReader.lzh_br_read_ahead_0(strm, br, 16))
                    {
                        if (!last)
                            /* We need following data. */
                            return Constants.ARCHIVE_OK;
                        if (LzhBitStreamReader.lzh_br_has(br, 8))
                        {
                            /*
                             * It seems there are extra bits.
                             *  1. Compressed data is broken.
                             *  2. `last' flag does not properly
                             *     set.
                             */
                            return ds.error = Constants.ARCHIVE_FAILED;
                        }

                        if (ds.w_pos > 0)
                        {
                            lzh_emit_window(strm, ds.w_pos);
                            ds.w_pos = 0;
                            return Constants.ARCHIVE_OK;
                        }

                        /* End of compressed data; we have completely
                         * handled all compressed data. */
                        return Constants.ARCHIVE_EOF;
                    }

                    ds.blocks_avail = LzhBitStreamReader.lzh_br_bits(br, 16);
                    if (ds.blocks_avail == 0)
                    {
                        return ds.error = Constants.ARCHIVE_FAILED;
                    }

                    LzhBitStreamReader.lzh_br_consume(br, 16);
                    /*
                     * Read a literal table compressed in huffman
                     * coding.
                     */
                    ds.pt.len_size = ds.literal_pt_len_size;
                    ds.pt.len_bits = ds.literal_pt_len_bits;
                    ds.reading_position = false;
                    /* FALL THROUGH */
                    fallThrough = true;
                }

                if (fallThrough || ds.state == ST_RD_PT_1)
                {
                    /* Note: ST_RD_PT_1, ST_RD_PT_2 and ST_RD_PT_4 are
                     * used in reading both a literal table and a
                     * position table. */
                    if (!LzhBitStreamReader.lzh_br_read_ahead(strm, br, (ushort)ds.pt.len_bits))
                    {
                        if (last)
                        {
                            // goto failed; /* Truncated data. */
                            return ds.error = Constants.ARCHIVE_FAILED;
                        }

                        ds.state = ST_RD_PT_1;
                        return Constants.ARCHIVE_OK;
                    }

                    ds.pt.len_avail = LzhBitStreamReader.lzh_br_bits(br, ds.pt.len_bits);
                    LzhBitStreamReader.lzh_br_consume(br, ds.pt.len_bits);
                    /* FALL THROUGH */
                    fallThrough = true;
                }

                if (fallThrough || ds.state == ST_RD_PT_2)
                {
                    if (ds.pt.len_avail == 0)
                    {
                        /* There is no bitlen. */
                        if (!LzhBitStreamReader.lzh_br_read_ahead(strm, br, (ushort)ds.pt.len_bits))
                        {
                            if (last)
                            {
                                // goto failed; /* Truncated data. */
                                return ds.error = Constants.ARCHIVE_FAILED;
                            }

                            ds.state = ST_RD_PT_2;
                            return Constants.ARCHIVE_OK;
                        }

                        if (!LzhHuffman.lzh_make_fake_table(ds.pt,
                                (ushort)LzhBitStreamReader.lzh_br_bits(br, ds.pt.len_bits)))
                        {
                            // goto failed; /* Invalid data */
                            return ds.error = Constants.ARCHIVE_FAILED;
                        }

                        LzhBitStreamReader.lzh_br_consume(br, ds.pt.len_bits);
                        if (ds.reading_position)
                            ds.state = ST_GET_LITERAL;
                        else
                            ds.state = ST_RD_LITERAL_1;
                        break;
                    }
                    else if (ds.pt.len_avail > ds.pt.len_size)
                    {
                        // goto failed; /* Invalid data */
                        return ds.error = Constants.ARCHIVE_FAILED;
                    }

                    ds.loop = 0;
                    //memset(ds.pt.freq, 0, sizeof(ds.pt.freq));
                    for (var x = 0; x < ds.pt.freq.Length; x++)
                    {
                        ds.pt.freq[x] = 0;
                    }
                    if (ds.pt.len_avail < 3 ||
                        ds.pt.len_size == ds.pos_pt_len_size)
                    {
                        ds.state = ST_RD_PT_4;
                        break;
                    }

                    /* FALL THROUGH */
                    fallThrough = true;
                }

                if (fallThrough || ds.state == ST_RD_PT_3)
                {
                    ds.loop = LzhHuffman.lzh_read_pt_bitlen(strm, ds.loop, 3);
                    if (ds.loop < 3)
                    {
                        if (ds.loop < 0 || last)
                        {
                            // goto failed; /* Invalid data */
                            return ds.error = Constants.ARCHIVE_FAILED;
                        }

                        /* Not completed, get following data. */
                        ds.state = ST_RD_PT_3;
                        return Constants.ARCHIVE_OK;
                    }

                    /* There are some null in bitlen of the literal. */
                    if (!LzhBitStreamReader.lzh_br_read_ahead(strm, br, 2))
                    {
                        if (last)
                        {
                            // goto failed; /* Truncated data. */
                            return ds.error = Constants.ARCHIVE_FAILED;
                        }

                        ds.state = ST_RD_PT_3;
                        return Constants.ARCHIVE_OK;
                    }

                    c = LzhBitStreamReader.lzh_br_bits(br, 2);
                    LzhBitStreamReader.lzh_br_consume(br, 2);
                    if (c > ds.pt.len_avail - 3)
                    {
                        // goto failed; /* Invalid data */
                        return ds.error = Constants.ARCHIVE_FAILED;
                    }

                    for (i = 3; c-- > 0;)
                        ds.pt.bitlen[i++] = 0;
                    ds.loop = i;
                    /* FALL THROUGH */
                    fallThrough = true;
                }

                if (fallThrough || ds.state == ST_RD_PT_4)
                {
                    ds.loop = LzhHuffman.lzh_read_pt_bitlen(strm, ds.loop, ds.pt.len_avail);
                    if (ds.loop < ds.pt.len_avail)
                    {
                        if (ds.loop < 0 || last)
                        {
                            // goto failed; /* Invalid data */
                            return ds.error = Constants.ARCHIVE_FAILED;
                        }

                        /* Not completed, get following data. */
                        ds.state = ST_RD_PT_4;
                        return Constants.ARCHIVE_OK;
                    }

                    if (!LzhHuffman.lzh_make_huffman_table(ds.pt))
                    {
                        // goto failed; /* Invalid data */
                        return ds.error = Constants.ARCHIVE_FAILED;
                    }

                    if (ds.reading_position)
                    {
                        ds.state = ST_GET_LITERAL;
                        break;
                    }

                    /* FALL THROUGH */
                    fallThrough = true;
                }

                if (fallThrough || ds.state == ST_RD_LITERAL_1)
                {
                    if (!LzhBitStreamReader.lzh_br_read_ahead(strm, br, (ushort)ds.lt.len_bits))
                    {
                        if (last)
                        {
                            // goto failed; /* Truncated data. */
                            return ds.error = Constants.ARCHIVE_FAILED;
                        }

                        ds.state = ST_RD_LITERAL_1;
                        return Constants.ARCHIVE_OK;
                    }

                    ds.lt.len_avail = LzhBitStreamReader.lzh_br_bits(br, ds.lt.len_bits);
                    LzhBitStreamReader.lzh_br_consume(br, ds.lt.len_bits);
                    /* FALL THROUGH */
                    fallThrough = true;
                }

                if (fallThrough || ds.state == ST_RD_LITERAL_2)
                {
                    if (ds.lt.len_avail == 0)
                    {
                        /* There is no bitlen. */
                        if (!LzhBitStreamReader.lzh_br_read_ahead(strm, br, (ushort)ds.lt.len_bits))
                        {
                            if (last)
                            {
                                // goto failed; /* Truncated data. */
                                return ds.error = Constants.ARCHIVE_FAILED;
                            }

                            ds.state = ST_RD_LITERAL_2;
                            return (Constants.ARCHIVE_OK);
                        }

                        if (!LzhHuffman.lzh_make_fake_table(ds.lt,
                                (ushort)LzhBitStreamReader.lzh_br_bits(br, ds.lt.len_bits)))
                        {
                            // goto failed; /* Invalid data */
                            return ds.error = Constants.ARCHIVE_FAILED;
                        }

                        LzhBitStreamReader.lzh_br_consume(br, ds.lt.len_bits);
                        ds.state = ST_RD_POS_DATA_1;
                        break;
                    }
                    else if (ds.lt.len_avail > ds.lt.len_size)
                    {
                        // goto failed; /* Invalid data */
                        return ds.error = Constants.ARCHIVE_FAILED;
                    }

                    ds.loop = 0;
                    //memset(ds.lt.freq, 0, sizeof(ds.lt.freq));
                    for (var x = 0; x < ds.lt.freq.Length; x++)
                    {
                        ds.lt.freq[x] = 0;
                    }
                    /* FALL THROUGH */
                    fallThrough = true;
                }

                if (fallThrough || ds.state == ST_RD_LITERAL_3)
                {
                    i = ds.loop;
                    while (i < ds.lt.len_avail)
                    {
                        if (!LzhBitStreamReader.lzh_br_read_ahead(strm, br, (ushort)ds.pt.max_bits))
                        {
                            if (last)
                            {
                                // goto failed; /* Truncated data. */
                                return ds.error = Constants.ARCHIVE_FAILED;
                            }

                            ds.loop = i;
                            ds.state = ST_RD_LITERAL_3;
                            return Constants.ARCHIVE_OK;
                        }

                        rbits = LzhBitStreamReader.lzh_br_bits(br, ds.pt.max_bits);
                        c = LzhHuffman.lzh_decode_huffman(ds.pt, rbits);
                        if (c > 2)
                        {
                            /* Note: 'c' will never be more than
                             * eighteen since it's limited by
                             * PT_BITLEN_SIZE, which is being set
                             * to ds.pt.len_size through
                             * ds.literal_pt_len_size. */
                            LzhBitStreamReader.lzh_br_consume(br, ds.pt.bitlen[c]);
                            c -= 2;
                            ds.lt.freq[c]++;
                            ds.lt.bitlen[i++] = (byte)c;
                        }
                        else if (c == 0)
                        {
                            LzhBitStreamReader.lzh_br_consume(br, ds.pt.bitlen[c]);
                            ds.lt.bitlen[i++] = 0;
                        }
                        else
                        {
                            /* c == 1 or c == 2 */
                            int n = (c == 1) ? 4 : 9;
                            if (!LzhBitStreamReader.lzh_br_read_ahead(strm, br, (ushort)(ds.pt.bitlen[c] + n)))
                            {
                                if (last)
                                {
                                    // goto failed; /* Truncated data. */
                                    return ds.error = Constants.ARCHIVE_FAILED;
                                }

                                ds.loop = i;
                                ds.state = ST_RD_LITERAL_3;
                                return Constants.ARCHIVE_OK;
                            }

                            LzhBitStreamReader.lzh_br_consume(br, ds.pt.bitlen[c]);
                            c = LzhBitStreamReader.lzh_br_bits(br, n);
                            LzhBitStreamReader.lzh_br_consume(br, n);
                            c += (n == 4) ? 3 : 20;
                            if (i + c > ds.lt.len_avail)
                            {
                                // goto failed; /* Invalid data */
                                return ds.error = Constants.ARCHIVE_FAILED;
                            }

                            //memset(&(ds.lt.bitlen[i]), 0, c);
                            for (var x = i; x < c; x++)
                            {
                                ds.lt.bitlen[x] = 0;
                            }
                            i += c;
                        }
                    }

                    if (i > ds.lt.len_avail || !LzhHuffman.lzh_make_huffman_table(ds.lt))
                    {
                        // goto failed; /* Invalid data */
                        return ds.error = Constants.ARCHIVE_FAILED;
                    }

                    /* FALL THROUGH */
                    fallThrough = true;
                }

                if (fallThrough || ds.state == ST_RD_POS_DATA_1)
                {
                    /*
                     * Read a position table compressed in huffman
                     * coding.
                     */
                    ds.pt.len_size = ds.pos_pt_len_size;
                    ds.pt.len_bits = ds.pos_pt_len_bits;
                    ds.reading_position = true;
                    ds.state = ST_RD_PT_1;
                    break;
                }

                if (ds.state == ST_GET_LITERAL)
                {
                    return 100;
                }
            }

            // should not reach this!
            return Constants.ARCHIVE_FAILED;
        }

        public static int lzh_decode_blocks(lzh_stream strm, bool last)
        {
            var ds = strm.ds;
            var bre = ds.br;
            var lt = ds.lt;
            var pt = ds.pt;
            var w_buff = ds.w_buff;
            var lt_bitlen = lt.bitlen;
            var pt_bitlen = pt.bitlen;
            int blocks_avail = ds.blocks_avail, c = 0;
            int copy_len = ds.copy_len, copy_pos = ds.copy_pos;
            int w_pos = ds.w_pos;
            uint w_mask = ds.w_mask, w_size = ds.w_size;
            int lt_max_bits = lt.max_bits, pt_max_bits = pt.max_bits;
            int state = ds.state;

            for (;;)
            {
                var fallThrough = false;
                if (state == ST_GET_LITERAL)
                {
                    for (;;)
                    {
                        if (blocks_avail == 0)
                        {
                            /* We have decoded all blocks.
                             * Let's handle next blocks. */
                            ds.state = ST_RD_BLOCK;
                            ds.br = bre;
                            ds.blocks_avail = 0;
                            ds.w_pos = w_pos;
                            ds.copy_pos = 0;
                            return 100;
                        }

                        /* lzh_br_read_ahead() always try to fill the
                         * cache buffer up. In specific situation we
                         * are close to the end of the data, the cache
                         * buffer will not be full and thus we have to
                         * determine if the cache buffer has some bits
                         * as much as we need after lzh_br_read_ahead()
                         * failed. */
                        if (!LzhBitStreamReader.lzh_br_read_ahead(strm, bre, (ushort)lt_max_bits))
                        {
                            if (!last)
                            {
                                // goto next_data;
                                NextData(ds, bre, blocks_avail, state, w_pos);
                                return Constants.ARCHIVE_OK;
                            }

                            /* Remaining bits are less than
                             * maximum bits(lt.max_bits) but maybe
                             * it still remains as much as we need,
                             * so we should try to use it with
                             * dummy bits. */
                            c = LzhHuffman.lzh_decode_huffman(lt,
                                LzhBitStreamReader.lzh_br_bits_forced(bre, lt_max_bits));
                            LzhBitStreamReader.lzh_br_consume(bre, lt_bitlen[c]);
                            if (!LzhBitStreamReader.lzh_br_has(bre, 0))
                            {
                                // goto failed; /* Over read. */
                                return ds.error = Constants.ARCHIVE_FAILED;
                            }
                        }
                        else
                        {
                            c = LzhHuffman.lzh_decode_huffman(lt, LzhBitStreamReader.lzh_br_bits(bre, lt_max_bits));
                            LzhBitStreamReader.lzh_br_consume(bre, lt_bitlen[c]);
                        }

                        blocks_avail--;
                        if (c > Constants.UCHAR_MAX)
                            /* Current block is a match data. */
                            break;
                        /*
                         * 'c' is exactly a literal code.
                         */
                        /* Save a decoded code to reference it
                         * afterward. */
                        w_buff[w_pos] = (byte)c;
                        if (++w_pos >= w_size)
                        {
                            w_pos = 0;
                            lzh_emit_window(strm, (int)w_size);
                            //goto next_data;
                            NextData(ds, bre, blocks_avail, state, w_pos);
                            return Constants.ARCHIVE_OK;
                        }
                    }

                    /* 'c' is the length of a match pattern we have
                     * already extracted, which has be stored in
                     * window(ds.w_buff). */
                    copy_len = c - (Constants.UCHAR_MAX + 1) + Constants.MINMATCH;
                    /* FALL THROUGH */
                    fallThrough = true;
                }

                if (fallThrough || state == ST_GET_POS_1)
                {

                    /*
                     * Get a reference position. 
                     */
                    if (!LzhBitStreamReader.lzh_br_read_ahead(strm, bre, (ushort)pt_max_bits))
                    {
                        if (!last)
                        {
                            state = ST_GET_POS_1;
                            ds.copy_len = copy_len;
                            //goto next_data;
                            NextData(ds, bre, blocks_avail, state, w_pos);
                            return Constants.ARCHIVE_OK;
                        }

                        copy_pos = LzhHuffman.lzh_decode_huffman(pt,
                            LzhBitStreamReader.lzh_br_bits_forced(bre, pt_max_bits));
                        LzhBitStreamReader.lzh_br_consume(bre, pt_bitlen[copy_pos]);
                        if (!LzhBitStreamReader.lzh_br_has(bre, 0))
                        {
                            // goto failed; /* Over read. */
                            return ds.error = Constants.ARCHIVE_FAILED;
                        }

                    }
                    else
                    {
                        copy_pos = LzhHuffman.lzh_decode_huffman(pt,
                            LzhBitStreamReader.lzh_br_bits(bre, pt_max_bits));
                        LzhBitStreamReader.lzh_br_consume(bre, pt_bitlen[copy_pos]);
                    }
                    /* FALL THROUGH */
                    fallThrough = true;
                }

                if (fallThrough || state == ST_GET_POS_2)
                {
                    if (copy_pos > 1)
                    {
                        /* We need an additional adjustment number to
                         * the position. */
                        int p = copy_pos - 1;
                        if (!LzhBitStreamReader.lzh_br_read_ahead(strm, bre, (ushort)p))
                        {
                            if (last)
                            {
                                // goto failed; /* Truncated data.*/
                                return ds.error = Constants.ARCHIVE_FAILED;
                            }

                            state = ST_GET_POS_2;
                            ds.copy_len = copy_len;
                            ds.copy_pos = copy_pos;
                            // goto next_data;
                            NextData(ds, bre, blocks_avail, state, w_pos);
                            return Constants.ARCHIVE_OK;
                        }

                        copy_pos = (1 << p) + LzhBitStreamReader.lzh_br_bits(bre, p);
                        LzhBitStreamReader.lzh_br_consume(bre, p);
                    }

                    /* The position is actually a distance from the last
                     * code we had extracted and thus we have to convert
                     * it to a position of the window. */
                    copy_pos = (int)((w_pos - copy_pos - 1) & w_mask);
                    /* FALL THROUGH */
                    fallThrough = true;
                }

                if (fallThrough || state == ST_COPY_DATA)
                {
                    /*
                     * Copy `copy_len' bytes as extracted data from
                     * the window into the output buffer.
                     */
                    for (;;)
                    {
                        int l;

                        l = copy_len;
                        if (copy_pos > w_pos)
                        {
                            if (l > w_size - copy_pos)
                                l = (int)(w_size - copy_pos);
                        }
                        else
                        {
                            if (l > w_size - w_pos)
                                l = (int)(w_size - w_pos);
                        }

                        if ((copy_pos + l < w_pos) || (w_pos + l < copy_pos))
                        {
                            /* No overlap. */
                            //memcpy(w_buff + w_pos, w_buff + copy_pos, l);
                            Array.Copy(w_buff, copy_pos, w_buff, w_pos, l);
                        }
                        else
                        {
                            //const unsigned  char* s;
                            //unsigned char* d;
                            // int li;
                            
                            // d = w_buff + w_pos;
                            // s = w_buff + copy_pos;
                            // for (li = 0; li < l - 1;)
                            // {
                            //     d[li] = s[li];
                            //     li++;
                            //     d[li] = s[li];
                            //     li++;
                            // }
                            //
                            // if (li < l)
                            //     d[li] = s[li];
                            
                            var d = w_pos;
                            var s = copy_pos;
                            int li;
                            for (li = 0; li < l - 1;)
                            {
                                w_buff[d + li] = w_buff[s + li];
                                li++;
                                w_buff[d + li] = w_buff[s + li];
                                li++;
                            }

                            if (li < l)
                                w_buff[d + li] = w_buff[s + li];
                        }

                        w_pos += l;
                        if (w_pos == w_size)
                        {
                            w_pos = 0;
                            lzh_emit_window(strm, (int)w_size);
                            if (copy_len <= l)
                                state = ST_GET_LITERAL;
                            else
                            {
                                state = ST_COPY_DATA;
                                ds.copy_len = copy_len - l;
                                ds.copy_pos = (int)((copy_pos + l) & w_mask);
                            }

                            //goto next_data;
                            NextData(ds, bre, blocks_avail, state, w_pos);
                            return Constants.ARCHIVE_OK;
                        }

                        if (copy_len <= l)
                            /* A copy of current pattern ended. */
                            break;
                        copy_len -= l;
                        copy_pos = (int)((copy_pos + l) & w_mask);
                    }

                    state = ST_GET_LITERAL;
                    break;
                }
            }

            /*
        failed:
            return (ds.error = ARCHIVE_FAILED);
        next_data:
            ds.br = bre;
            ds.blocks_avail = blocks_avail;
            ds.state = state;
            ds.w_pos = w_pos;
        */
            return Constants.ARCHIVE_OK;
        }

        private static void NextData(lzh_dec ds, lzh_br bre, int blocks_avail, int state, int w_pos)
        {
            ds.br = bre;
            ds.blocks_avail = blocks_avail;
            ds.state = state;
            ds.w_pos = w_pos;
        }
    }
}