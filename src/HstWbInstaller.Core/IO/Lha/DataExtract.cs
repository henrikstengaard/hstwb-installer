// namespace HstWbInstaller.Core.IO.Lha
// {
//     using System;
//     using System.IO;
//
//     public static class DataExtract
//     {
//         private const int HTBL_BITS = 10;
//         private const byte UCHAR_MAX = (1 << 8) - 1;
//         private const int MAXMATCH = 256; /* Maximum match length. */
//         private const int MINMATCH = 3; /* Minimum match length. */
//
//         /* Literal table size. */
//         private const int LT_BITLEN_SIZE = (UCHAR_MAX + 1 + MAXMATCH - MINMATCH + 1);
//
//         /* Position table size.
//          * Note: this used for both position table and pre literal table.*/
//         private const int PT_BITLEN_SIZE = 3 + 16;
//
//         private const int ST_RD_BLOCK = 0;
//         private const int ST_RD_PT_1 = 1;
//         private const int ST_RD_PT_2 = 2;
//         private const int ST_RD_PT_3 = 3;
//         private const int ST_RD_PT_4 = 4;
//         private const int ST_RD_LITERAL_1 = 5;
//         private const int ST_RD_LITERAL_2 = 6;
//         private const int ST_RD_LITERAL_3 = 7;
//         private const int ST_RD_POS_DATA_1 = 8;
//         private const int ST_GET_LITERAL = 9;
//         private const int ST_GET_POS_1 = 10;
//         private const int ST_GET_POS_2 = 11;
//         private const int ST_COPY_DATA = 12;
//
//         // https://github.com/libarchive/libarchive/blob/master/libarchive/archive_read_support_format_lha.c#L1546
//         public static void lha_read_data_lzh(Stream stream, string method)
//         {
//             //r = lzh_decode_init(&(lha->strm), lha->method);
//             var lzhStream = new lzh_stream
//             {
//                 ds = lzh_decode_init(method)
//             };
//
//             lzhStream.next_in = (byte)stream.ReadByte();
//             //lha->strm.next_in = __archive_read_ahead(a, 1, &bytes_avail);
//
//             //r = lzh_decode(&(lha->strm), bytes_avail == lha->entry_bytes_remaining);
//         }
//
//         public static bool lzh_decode(lzh_stream lzhStream, bool last)
//         {
//             if (lzhStream.ds.error)
//                 return false;
//
//             int r;
//             do
//             {
//                 if (lzhStream.ds.State < ST_GET_LITERAL)
//                     r = lzh_read_blocks(lzhStream, last);
//                 else
//                     r = lzh_decode_blocks(lzhStream, last);
//             } while (r == 100);
//
//             lzhStream.total_in += avail_in - lzhStream.avail_in;
//         }
//
// /*
//  * Shift away used bits in the cache data and fill it up with following bits.
//  * Call this when cache buffer does not have enough bits you need.
//  *
//  * Returns 1 if the cache buffer is full.
//  * Returns 0 if the cache buffer is not full; input buffer is empty.
//  */
//         private static bool lzh_br_fillup(lzh_stream strm, LzhDec.lzh_br br)
//         {
//             int n = CACHE_BITS - br.cache_avail;
//
//             for (;;)
//             {
//                 const int x = n >> 3;
//                 if (strm.avail_in >= x)
//                 {
//                     switch (x)
//                     {
//                         case 8:
//                             br.cache_buffer =
//                                 ((ulong)strm.next_in[0]) << 56 |
//                                 ((uint64_t)strm.next_in[1]) << 48 |
//                                 ((uint64_t)strm.next_in[2]) << 40 |
//                                 ((uint64_t)strm.next_in[3]) << 32 |
//                                 ((uint32_t)strm.next_in[4]) << 24 |
//                                 ((uint32_t)strm.next_in[5]) << 16 |
//                                 ((uint32_t)strm.next_in[6]) << 8 |
//                                 (uint32_t)strm.next_in[7];
//                             strm.next_in += 8;
//                             strm.avail_in -= 8;
//                             br.cache_avail += 8 * 8;
//                             return true;
//                         case 7:
//                             br.cache_buffer =
//                                 (br.cache_buffer << 56) |
//                                 ((uint64_t)strm.next_in[0]) << 48 |
//                                 ((uint64_t)strm.next_in[1]) << 40 |
//                                 ((uint64_t)strm.next_in[2]) << 32 |
//                                 ((uint32_t)strm.next_in[3]) << 24 |
//                                 ((uint32_t)strm.next_in[4]) << 16 |
//                                 ((uint32_t)strm.next_in[5]) << 8 |
//                                 (uint32_t)strm.next_in[6];
//                             strm.next_in += 7;
//                             strm.avail_in -= 7;
//                             br.cache_avail += 7 * 8;
//                             return true;
//                         case 6:
//                             br.cache_buffer =
//                                 (br.cache_buffer << 48) |
//                                 ((uint64_t)strm.next_in[0]) << 40 |
//                                 ((uint64_t)strm.next_in[1]) << 32 |
//                                 ((uint32_t)strm.next_in[2]) << 24 |
//                                 ((uint32_t)strm.next_in[3]) << 16 |
//                                 ((uint32_t)strm.next_in[4]) << 8 |
//                                 (uint32_t)strm.next_in[5];
//                             strm.next_in += 6;
//                             strm.avail_in -= 6;
//                             br.cache_avail += 6 * 8;
//                             return true;
//                         case 0:
//                             /* We have enough compressed data in
//                              * the cache buffer.*/
//                             return true;
//                     }
//                 }
//
//                 if (strm.avail_in == 0)
//                 {
//                     /* There is not enough compressed data to fill up the
//                      * cache buffer. */
//                     return false;
//                 }
//
//                 br.cache_buffer =
//                     (br.cache_buffer << 8) | strm->next_in++;
//                 strm.avail_in--;
//                 br.cache_avail += 8;
//                 n -= 8;
//             }
//         }
//
//         public const int ARCHIVE_EOF = 1; /* Found end of archive. */
//         public const int ARCHIVE_OK = 0; /* Operation was successful. */
//         public const int ARCHIVE_RETRY = -10; /* Retry might succeed. */
//
//         public const int ARCHIVE_WARN = -20; /* Partial success. */
//
//         /* For example, if write_header "fails", then you can't push data. */
//         public const int ARCHIVE_FAILED = -25; /* Current operation cannot complete. */
//
//         /* But if write_header is "fatal," then this archive is dead and useless. */
//         public const int ARCHIVE_FATAL = -30; /* No more operations are possible. */
//
//         /* Read ahead to make sure the cache buffer has enough compressed data we
//          * will use.
//          *  True  : completed, there is enough data in the cache buffer.
//          *  False : we met that strm->next_in is empty, we have to get following
//          *          bytes. */
//         private static bool lzh_br_read_ahead_0(lzh_stream strm, LzhDec.lzh_br br, ushort n)
//         {
//             return lzh_br_has(br, n) || lzh_br_fillup(strm, br);
//         }
//
//         /*  True  : the cache buffer has some bits as much as we need.
//          *  False : there are no enough bits in the cache buffer to be used,
//          *          we have to get following bytes if we could. */
//         private static bool lzh_br_read_ahead(lzh_stream strm, LzhDec.lzh_br br, ushort n)
//         {
//             return lzh_br_read_ahead_0(strm, br, n) || lzh_br_has(br, n);
//         }
//
//         // Check that the cache buffer has enough bits.
//         private static bool lzh_br_has(LzhDec.lzh_br br, int n) => br.cache_avail >= n;
//
//         /* Notify how many bits we consumed. */
//         private static void lzh_br_consume(LzhDec.lzh_br br, int n) => br.cache_avail -= n;
//
//         private static ushort[] cache_masks =
//         {
//             0x0000, 0x0001, 0x0003, 0x0007,
//             0x000F, 0x001F, 0x003F, 0x007F,
//             0x00FF, 0x01FF, 0x03FF, 0x07FF,
//             0x0FFF, 0x1FFF, 0x3FFF, 0x7FFF,
//             0xFFFF, 0xFFFF, 0xFFFF, 0xFFFF
//         };
//
//         /* Get compressed data by bit. */
//         private static ushort lzh_br_bits(LzhDec.lzh_br br, int n)
//         {
//             return (ushort)(br.cache_buffer >> (br.cache_avail - n)) & cache_masks[n];
//         }
//
//         private static void lzh_emit_window(lzh_stream strm, int s)
//         {
//             strm.ref_ptr = strm.ds.w_buff;
//             strm.avail_out = s;
//             strm.total_out += s;
//         }
//
//         private static int lzh_read_blocks(lzh_stream strm, bool last)
//         {
//             int c = 0, i;
//             byte rbits;
//             var ds = strm.ds;
//             var br = ds.br;
//
//             for (;;)
//             {
//                 if (strm.ds.State == ST_RD_BLOCK)
//                 {
//                     /*
//                      * Read a block number indicates how many blocks
//                      * we will handle. The block is composed of a
//                      * literal and a match, sometimes a literal only
//                      * in particular, there are no reference data at
//                      * the beginning of the decompression.
//                      */
//                     if (!lzh_br_read_ahead_0(strm, ds.br, 16))
//                     {
//                         if (!last)
//                             /* We need following data. */
//                             return ARCHIVE_OK;
//                         if (lzh_br_has(ds.br, 8))
//                         {
//                             /*
//                              * It seems there are extra bits.
//                              *  1. Compressed data is broken.
//                              *  2. `last' flag does not properly
//                              *     set.
//                              */
//                             ds.error = ARCHIVE_FAILED;
//                             return ds.error;
//                         }
//
//                         if (ds.w_pos > 0)
//                         {
//                             lzh_emit_window(strm, ds.w_pos);
//                             ds.w_pos = 0;
//                             return ARCHIVE_OK;
//                         }
//
//                         /* End of compressed data; we have completely
//                          * handled all compressed data. */
//                         return ARCHIVE_EOF;
//                     }
//
//                     ds.blocks_avail = lzh_br_bits(br, 16);
//                     if (ds.blocks_avail == 0)
//                     {
//                         ds.error = ARCHIVE_FAILED;
//                         return ds.error;
//                     }
//
//                     lzh_br_consume(br, 16);
//                     /*
//                      * Read a literal table compressed in huffman
//                      * coding.
//                      */
//                     ds.pt.len_size = ds.literal_pt_len_size;
//                     ds.pt.len_bits = ds.literal_pt_len_bits;
//                     ds.reading_position = false;
//                     /* FALL THROUGH */
//                 }
//
//                 if (strm.ds.State == ST_RD_PT_1)
//                 {
//                     /* Note: ST_RD_PT_1, ST_RD_PT_2 and ST_RD_PT_4 are
//                      * used in reading both a literal table and a
//                      * position table. */
//                     if (!lzh_br_read_ahead(strm, br, ds.pt.len_bits))
//                     {
//                         if (last)
//                         {
//                             //goto failed;/* Truncated data.*/
//                             ds.error = ARCHIVE_FAILED;
//                             return ds.error;
//                         }
//
//                         ds.State = ST_RD_PT_1;
//                         return ARCHIVE_OK;
//                     }
//
//                     ds.pt.len_avail = lzh_br_bits(br, ds.pt.len_bits);
//                     lzh_br_consume(br, ds.pt.len_bits);
//                     /* FALL THROUGH */
//                 }
//
//                 if (strm.ds.State == ST_RD_PT_2)
//                 {
//                     if (ds.pt.len_avail == 0)
//                     {
//                         /* There is no bitlen. */
//                         if (!lzh_br_read_ahead(strm, br, ds.pt.len_bits))
//                         {
//                             if (last)
//                             {
//                                 //goto failed;/* Truncated data.*/
//                                 ds.error = ARCHIVE_FAILED;
//                                 return ds.error;
//                             }
//
//                             ds.State = ST_RD_PT_2;
//                             return ARCHIVE_OK;
//                         }
//
//                         if (!lzh_make_fake_table(ds.pt, lzh_br_bits(ds.br, ds.pt.len_bits)))
//                         {
//                             //goto failed;/* Invalid data */
//                             ds.error = ARCHIVE_FAILED;
//                             return ds.error;
//                         }
//
//                         lzh_br_consume(ds.br, ds.pt.len_bits);
//                         if (ds.reading_position)
//                             ds.State = ST_GET_LITERAL;
//                         else
//                             ds.State = ST_RD_LITERAL_1;
//                         break;
//                     }
//                     else if (ds.pt.len_avail > ds.pt.len_size)
//                     {
//                         //goto failed;/* Invalid data */
//                         ds.error = ARCHIVE_FAILED;
//                         return ds.error;
//                     }
//
//                     ds.loop = 0;
//                     ds.pt.freq = new int[17];
//                     //memset(ds->pt.freq, 0, sizeof(ds->pt.freq));
//                     if (ds.pt.len_avail < 3 || ds.pt.len_size == ds.pos_pt_len_size)
//                     {
//                         ds.State = ST_RD_PT_4;
//                         break;
//                     }
//                     /* FALL THROUGH */
//                 }
//
//                 if (strm.ds.State == ST_RD_PT_3)
//                 {
//                     ds.loop = lzh_read_pt_bitlen(strm, ds.loop, 3);
//                     if (ds.loop < 3)
//                     {
//                         if (ds.loop < 0 || last)
//                         {
//                             //goto failed;/* Invalid data */
//                             ds.error = ARCHIVE_FAILED;
//                             return ds.error;
//                         }
//
//                         /* Not completed, get following data. */
//                         ds.State = ST_RD_PT_3;
//                         return ARCHIVE_OK;
//                     }
//
//                     /* There are some null in bitlen of the literal. */
//                     if (!lzh_br_read_ahead(strm, ds.br, 2))
//                     {
//                         if (last)
//                         {
//                             //goto failed;/* Truncated data.*/
//                             ds.error = ARCHIVE_FAILED;
//                             return ds.error;
//                         }
//
//                         ds.State = ST_RD_PT_3;
//                         return ARCHIVE_OK;
//                     }
//
//                     c = lzh_br_bits(ds.br, 2);
//                     lzh_br_consume(ds.br, 2);
//                     if (c > ds.pt.len_avail - 3)
//                     {
//                         //goto failed;/* Invalid data */
//                         ds.error = ARCHIVE_FAILED;
//                         return ds.error;
//                     }
//
//                     for (i = 3; c-- > 0;)
//                         ds.pt.bitlen[i++] = 0;
//                     ds.loop = i;
//                     /* FALL THROUGH */
//                 }
//
//                 if (strm.ds.State == ST_RD_PT_4)
//                 {
//                     ds.loop = lzh_read_pt_bitlen(strm, ds.loop, ds.pt.len_avail);
//                     if (ds.loop < ds.pt.len_avail)
//                     {
//                         if (ds.loop < 0 || last)
//                         {
//                             //goto failed;/* Invalid data */
//                             ds.error = ARCHIVE_FAILED;
//                             return ds.error;
//                         }
//
//                         /* Not completed, get following data. */
//                         ds.State = ST_RD_PT_4;
//                         return ARCHIVE_OK;
//                     }
//
//                     if (!lzh_make_huffman_table(ds.pt))
//                     {
//                         //goto failed;/* Invalid data */
//                         ds.error = ARCHIVE_FAILED;
//                         return ds.error;
//                     }
//
//                     if (ds.reading_position)
//                     {
//                         ds.State = ST_GET_LITERAL;
//                         break;
//                     }
//                     /* FALL THROUGH */
//                 }
//
//                 if (strm.ds.State == ST_RD_LITERAL_1)
//                 {
//                     if (!lzh_br_read_ahead(strm, br, ds.lt.len_bits))
//                     {
//                         if (last)
//                         {
//                             //goto failed;/* Truncated data.*/
//                             ds.error = ARCHIVE_FAILED;
//                             return ds.error;
//                         }
//
//                         ds.State = ST_RD_LITERAL_1;
//                         return ARCHIVE_OK;
//                     }
//
//                     ds.lt.len_avail = lzh_br_bits(br, ds.lt.len_bits);
//                     lzh_br_consume(br, ds.lt.len_bits);
//                     /* FALL THROUGH */
//                 }
//
//                 if (strm.ds.State == ST_RD_LITERAL_2)
//                 {
//                     if (ds.lt.len_avail == 0)
//                     {
//                         /* There is no bitlen. */
//                         if (!lzh_br_read_ahead(strm, br, ds.lt.len_bits))
//                         {
//                             if (last)
//                             {
//                                 //goto failed;/* Truncated data.*/
//                                 ds.error = ARCHIVE_FAILED;
//                                 return ds.error;
//                             }
//
//                             ds.State = ST_RD_LITERAL_2;
//                             return ARCHIVE_OK;
//                         }
//
//                         if (!lzh_make_fake_table(ds.lt, lzh_br_bits(br, ds.lt.len_bits)))
//                         {
//                             //goto failed;/* Invalid data */
//                             ds.error = ARCHIVE_FAILED;
//                             return ds.error;
//                         }
//
//                         lzh_br_consume(br, ds.lt.len_bits);
//                         ds.State = ST_RD_POS_DATA_1;
//                         break;
//                     }
//                     else if (ds.lt.len_avail > ds.lt.len_size)
//                     {
//                         //goto failed;/* Invalid data */
//                         ds.error = ARCHIVE_FAILED;
//                         return ds.error;
//                     }
//
//                     ds.loop = 0;
//                     //memset(ds->lt.freq, 0, sizeof(ds->lt.freq));
//                     ds.lt.freq = new int[17];
//                     /* FALL THROUGH */
//                 }
//
//                 if (strm.ds.State == ST_RD_LITERAL_3)
//                 {
//                     i = ds.loop;
//                     while (i < ds.lt.len_avail)
//                     {
//                         if (!lzh_br_read_ahead(strm, br, ds.pt.max_bits))
//                         {
//                             if (last) /* Truncated data. */
//                             {
//                                 //goto failed;/* Invalid data */
//                                 ds.error = ARCHIVE_FAILED;
//                                 return ds.error;
//                             }
//
//                             ds.loop = i;
//                             ds.State = ST_RD_LITERAL_3;
//                             return ARCHIVE_OK;
//                         }
//
//                         rbits = lzh_br_bits(br, ds.pt.max_bits);
//                         c = lzh_decode_huffman(ds.pt, rbits);
//                         if (c > 2)
//                         {
//                             /* Note: 'c' will never be more than
//                              * eighteen since it's limited by
//                              * PT_BITLEN_SIZE, which is being set
//                              * to ds->pt.len_size through
//                              * ds->literal_pt_len_size. */
//                             lzh_br_consume(ds.br, ds.pt.bitlen[c]);
//                             c -= 2;
//                             ds.lt.freq[c]++;
//                             ds.lt.bitlen[i++] = c;
//                         }
//                         else if (c == 0)
//                         {
//                             lzh_br_consume(ds.br, ds.pt.bitlen[c]);
//                             ds.lt.bitlen[i++] = 0;
//                         }
//                         else
//                         {
//                             /* c == 1 or c == 2 */
//                             int n = (c == 1) ? 4 : 9;
//                             if (!lzh_br_read_ahead(strm, ds.br, ds.pt.bitlen[c] + n))
//                             {
//                                 if (last) /* Truncated data. */
//                                 {
//                                     //goto failed;/* Invalid data */
//                                     ds.error = ARCHIVE_FAILED;
//                                     return ds.error;
//                                 }
//
//                                 ds.loop = i;
//                                 ds.State = ST_RD_LITERAL_3;
//                                 return (ARCHIVE_OK);
//                             }
//
//                             lzh_br_consume(br, ds.pt.bitlen[c]);
//                             c = lzh_br_bits(br, n);
//                             lzh_br_consume(br, n);
//                             c += n == 4 ? 3 : 20;
//                             if (i + c > ds.lt.len_avail)
//                             {
//                                 //goto failed;/* Invalid data */
//                                 ds.error = ARCHIVE_FAILED;
//                                 return ds.error;
//                             }
//
//                             //memset(&(ds->lt.bitlen[i]), 0, c);
//                             ds.lt.bitlen[i] = new int[c];
//                             i += c;
//                         }
//                     }
//
//                     if (i > ds.lt.len_avail || !lzh_make_huffman_table(ds.lt))
//                     {
//                         //goto failed;/* Invalid data */
//                         ds.error = ARCHIVE_FAILED;
//                         return ds.error;
//                     }
//                     /* FALL THROUGH */
//                 }
//
//                 if (strm.ds.State == ST_RD_POS_DATA_1)
//                 {
//                     /*
//                      * Read a position table compressed in huffman
//                      * coding.
//                      */
//                     ds.pt.len_size = ds.pos_pt_len_size;
//                     ds.pt.len_bits = ds.pos_pt_len_bits;
//                     ds.reading_position = true;
//                     ds.State = ST_RD_PT_1;
//                     break;
//                 }
//
//                 if (strm.ds.State == ST_GET_LITERAL)
//                 {
//                     return 100;
//                 }
//             }
//
//             // should not reach this
//             return ARCHIVE_FAILED;
//         }
//         
// /*
//  * Make a huffman coding table.
//  */
// private static bool lzh_make_huffman_table(LzhDec.huffman hf)
// {
// 	var bitptn = new int[17];
//     var weight = new int[17];
// 	int i, maxbits = 0, tbl_size, w;
// 	int diffbits, len_avail;
//
// 	/*
// 	 * Initialize bit patterns.
// 	 */
// 	var ptn = 0;
// 	for (i = 1, w = 1 << 15; i <= 16; i++, w >>= 1) {
// 		bitptn[i] = ptn;
// 		weight[i] = w;
// 		if (hf.freq[i] != 0) {
// 			ptn += hf.freq[i] * w;
// 			maxbits = i;
// 		}
// 	}
//
//     if (ptn != 0x10000 || maxbits > hf.tbl_bits)
//     {
//         return false;/* Invalid */
//     }
//
// 	hf.max_bits = maxbits;
//
// 	/*
// 	 * Cut out extra bits which we won't house in the table.
// 	 * This preparation reduces the same calculation in the for-loop
// 	 * making the table.
// 	 */
// 	if (maxbits < 16)
//     {
// 		int ebits = 16 - maxbits;
// 		for (i = 1; i <= maxbits; i++)
//         {
// 			bitptn[i] >>= ebits;
// 			weight[i] >>= ebits;
// 		}
// 	}
// 	if (maxbits > HTBL_BITS)
//     {
// 		int htbl_max;
//
// 		diffbits = maxbits - HTBL_BITS;
// 		for (i = 1; i <= HTBL_BITS; i++) {
// 			bitptn[i] >>= diffbits;
// 			weight[i] >>= diffbits;
// 		}
// 		htbl_max = bitptn[HTBL_BITS] +
// 		    weight[HTBL_BITS] * hf.freq[HTBL_BITS];
// 		var p = hf.tbl[htbl_max];
// 		while (p < hf.tbl[1U<<HTBL_BITS])
// 			p++ = 0;
// 	} else
// 		diffbits = 0;
// 	hf.shift_bits = diffbits;
//
// 	/*
// 	 * Make the table.
// 	 */
// 	tbl_size = 1 << HTBL_BITS;
// 	var tbl = hf.tbl;
// 	var bitlen = hf.bitlen;
// 	len_avail = hf.len_avail;
// 	hf.tree_used = 0;
// 	for (i = 0; i < len_avail; i++) {
// 		uint16_t *p;
// 		int len, cnt;
// 		uint16_t bit;
// 		int extlen;
// 		struct htree_t *ht;
//
//         if (bitlen[i] == 0)
//         {
//             continue;
//         }
//         
// 		/* Get a bit pattern */
// 		len = bitlen[i];
// 		ptn = bitptn[len];
// 		cnt = weight[len];
// 		if (len <= HTBL_BITS) {
// 			/* Calculate next bit pattern */
// 			if ((bitptn[len] = ptn + cnt) > tbl_size)
// 				return false;/* Invalid */
// 			/* Update the table */
// 			var p = tbl[ptn];
// 			if (cnt > 7) {
// 				uint16_t *pc;
//
// 				cnt -= 8;
// 				pc = &p[cnt];
// 				pc[0] = (uint16_t)i;
// 				pc[1] = (uint16_t)i;
// 				pc[2] = (uint16_t)i;
// 				pc[3] = (uint16_t)i;
// 				pc[4] = (uint16_t)i;
// 				pc[5] = (uint16_t)i;
// 				pc[6] = (uint16_t)i;
// 				pc[7] = (uint16_t)i;
// 				if (cnt > 7) {
// 					cnt -= 8;
// 					memcpy(&p[cnt], pc,
// 						8 * sizeof(uint16_t));
// 					pc = &p[cnt];
// 					while (cnt > 15) {
// 						cnt -= 16;
// 						memcpy(&p[cnt], pc,
// 							16 * sizeof(uint16_t));
// 					}
// 				}
// 				if (cnt)
// 					memcpy(p, pc, cnt * sizeof(uint16_t));
// 			} else {
// 				while (cnt > 1) {
// 					p[--cnt] = (uint16_t)i;
// 					p[--cnt] = (uint16_t)i;
// 				}
// 				if (cnt)
// 					p[--cnt] = (uint16_t)i;
// 			}
// 			continue;
// 		}
//
// 		/*
// 		 * A bit length is too big to be housed to a direct table,
// 		 * so we use a tree model for its extra bits.
// 		 */
// 		bitptn[len] = ptn + cnt;
// 		bit = 1U << (diffbits -1);
// 		extlen = len - HTBL_BITS;
// 		
// 		p = &(tbl[ptn >> diffbits]);
// 		if (*p == 0) {
// 			*p = len_avail + hf->tree_used;
// 			ht = &(hf->tree[hf->tree_used++]);
// 			if (hf->tree_used > hf->tree_avail)
// 				return (0);/* Invalid */
// 			ht->left = 0;
// 			ht->right = 0;
// 		} else {
// 			if (*p < len_avail ||
// 			    *p >= (len_avail + hf->tree_used))
// 				return (0);/* Invalid */
// 			ht = &(hf->tree[*p - len_avail]);
// 		}
// 		while (--extlen > 0) {
// 			if (ptn & bit) {
// 				if (ht->left < len_avail) {
// 					ht->left = len_avail + hf->tree_used;
// 					ht = &(hf->tree[hf->tree_used++]);
// 					if (hf->tree_used > hf->tree_avail)
// 						return (0);/* Invalid */
// 					ht->left = 0;
// 					ht->right = 0;
// 				} else {
// 					ht = &(hf->tree[ht->left - len_avail]);
// 				}
// 			} else {
// 				if (ht->right < len_avail) {
// 					ht->right = len_avail + hf->tree_used;
// 					ht = &(hf->tree[hf->tree_used++]);
// 					if (hf->tree_used > hf->tree_avail)
// 						return (0);/* Invalid */
// 					ht->left = 0;
// 					ht->right = 0;
// 				} else {
// 					ht = &(hf->tree[ht->right - len_avail]);
// 				}
// 			}
// 			bit >>= 1;
// 		}
// 		if (ptn & bit) {
// 			if (ht->left != 0)
// 				return (0);/* Invalid */
// 			ht->left = (uint16_t)i;
// 		} else {
// 			if (ht->right != 0)
// 				return (0);/* Invalid */
// 			ht->right = (uint16_t)i;
// 		}
// 	}
// 	return (1);
// }        
//
//         public static LzhDec lzh_decode_init(string method)
//         {
//             // https://github.com/libarchive/libarchive/blob/master/libarchive/archive_read_support_format_lha.c#L1859
//             int w_bits;
//
//             switch (method)
//             {
//                 case Constants.LZHUFF5_METHOD:
//                     w_bits = 13; /* 8KiB for window */
//                     break;
//                 case Constants.LZHUFF6_METHOD:
//                     w_bits = 15; /* 32KiB for window */
//                     break;
//                 case Constants.LZHUFF7_METHOD:
//                     w_bits = 16; /* 64KiB for window */
//                     break;
//                 default:
//                     throw new NotSupportedException($"Method '{method}' not supported");
//             }
//
//             /* Expand a window size up to 128 KiB for decompressing process
//              * performance whatever its original window size is. */
//             var w_size = 1U << 17;
//             var lzhDec = new LzhDec
//             {
//                 w_size = w_size,
//                 w_mask = w_size - 1,
//                 w_buff = new byte[w_size]
//             };
//
//             w_size = 1U << w_bits;
//             for (var i = 0; i < w_size; i++)
//             {
//                 lzhDec.w_buff[i] = 0x20;
//             }
//
//             lzhDec.w_pos = 0;
//             lzhDec.State = 0;
//
//             lzhDec.pos_pt_len_size = w_bits + 1;
//             lzhDec.pos_pt_len_bits = (w_bits == 15 || w_bits == 16) ? 5 : 4;
//             lzhDec.literal_pt_len_size = PT_BITLEN_SIZE;
//             lzhDec.literal_pt_len_bits = 5;
//             lzhDec.br.cache_buffer = 0;
//             lzhDec.br.cache_avail = 0;
//
//             lzh_huffman_init(lzhDec.lt, LT_BITLEN_SIZE, 16);
//             lzhDec.lt.len_bits = 9;
//             lzh_huffman_init(lzhDec.pt, PT_BITLEN_SIZE, 16);
//             lzhDec.error = false;
//
//             return lzhDec;
//         }
//
//         private static void lzh_huffman_init(LzhDec.huffman huffman, int len_size, int tbl_bits)
//         {
//             if (huffman.bitlen == null)
//             {
//                 huffman.bitlen = new byte[len_size];
//             }
//
//             if (huffman.tbl == null)
//             {
//                 int bits;
//                 if (tbl_bits < HTBL_BITS)
//                     bits = tbl_bits;
//                 else
//                     bits = HTBL_BITS;
//                 huffman.tbl = new ushort[1 << bits]; // malloc(((size_t)1 << bits) * sizeof(hf->tbl[0]));
//             }
//
//             if (huffman.tree == null && tbl_bits > HTBL_BITS)
//             {
//                 huffman.tree_avail = 1 << (tbl_bits - HTBL_BITS + 4);
//                 huffman.tree =
//                     new LzhDec.huffman.htree_t[huffman.tree_avail]; // malloc(hf->tree_avail * sizeof(hf->tree[0]));
//             }
//
//             huffman.len_size = len_size;
//             huffman.tbl_bits = tbl_bits;
//         }
//     }
// }