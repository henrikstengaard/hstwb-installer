namespace HstWbInstaller.Core.IO.Lha.Decode
{
    using System;

    public static class LzhHuffman
    {
        // conversion
        // unsigned = int
        // uint16_t = ushort

        // if (int) = if ( != 0)

        /* There is no difference between:
        *(array+10); //and
        array[10];
        */

        // ---------------------------------------

        public static void lzh_huffman_init(huffman hf, int len_size, int tbl_bits)
        {
            int bits;

            if (hf.bitlen == null) {
                //hf.bitlen = malloc(len_size * sizeof(hf.bitlen[0]));
                hf.bitlen = new byte[len_size];
            }
            if (hf.tbl == null) {
                if (tbl_bits < Constants.HTBL_BITS)
                    bits = tbl_bits;
                else
                    bits = Constants.HTBL_BITS;
                //hf.tbl = malloc(((size_t)1 << bits) * sizeof(hf.tbl[0]));
                hf.tbl = new ushort[1 << bits];
            }
            if (hf.tree == null && tbl_bits > Constants.HTBL_BITS) {
                hf.tree_avail = 1 << (tbl_bits - Constants.HTBL_BITS + 4);
                //hf.tree = malloc(hf.tree_avail * sizeof(hf.tree[0]));
                hf.tree = new htree_t[hf.tree_avail];
            }
            hf.len_size = (int)len_size;
            hf.tbl_bits = tbl_bits;
        }
        
        public static readonly byte[] bitlen_tbl =
        {
            7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7,
            7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7,
            7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7,
            7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7,
            7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7,
            7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7,
            7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7,
            7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7,
            7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7,
            7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7,
            7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7,
            7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7,
            7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7,
            7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7,
            7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7,
            7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7,
            7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7,
            7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7,
            7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7,
            7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7,
            7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7,
            7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7,
            7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7,
            7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7,
            7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7,
            7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7,
            7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7,
            7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7,
            7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7,
            7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7,
            7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7,
            7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7,
            8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8,
            8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8,
            8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8,
            8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8,
            8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8,
            8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8,
            8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8,
            8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8,
            8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8,
            8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8,
            8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8,
            8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8,
            8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8,
            8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8,
            8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8,
            8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8,
            9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9,
            9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9,
            9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9,
            9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9,
            9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9,
            9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9,
            9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9,
            9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9,
            10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10,
            10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10,
            10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10,
            10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10,
            11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11,
            11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11,
            12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12,
            13, 13, 13, 13, 13, 13, 13, 13, 14, 14, 14, 14, 15, 15, 16, 0
        };


        public static int lzh_read_pt_bitlen(lzh_stream strm, int start, int end)
        {
            var ds = strm.ds;
            var br = ds.br;
            //int c, i;

            int i;
            for (i = start; i < end;)
            {
                /*
                 *  bit pattern     the number we need
                 *     000           ->  0
                 *     001           ->  1
                 *     010           ->  2
                 *     ...
                 *     110           ->  6
                 *     1110          ->  7
                 *     11110         ->  8
                 *     ...
                 *     1111111111110 ->  16
                 */
                if (!LzhBitStreamReader.lzh_br_read_ahead(strm, br, 3))
                    return i;
                int c;
                if ((c = LzhBitStreamReader.lzh_br_bits(br, 3)) == 7)
                {
                    if (!LzhBitStreamReader.lzh_br_read_ahead(strm, br, 13))
                        return i;
                    c = bitlen_tbl[LzhBitStreamReader.lzh_br_bits(br, 13) & 0x3FF];
                    if (c != 0)
                        LzhBitStreamReader.lzh_br_consume(br, c - 3);
                    else
                        return -1; /* Invalid data. */
                }
                else
                    LzhBitStreamReader.lzh_br_consume(br, 3);

                ds.pt.bitlen[i++] = (byte)c;
                ds.pt.freq[c]++;
            }

            return i;
        }
        
        public static bool lzh_make_fake_table(huffman hf, ushort c)
        {
            if (c >= hf.len_size)
                return false;
            hf.tbl[0] = c;
            hf.max_bits = 0;
            hf.shift_bits = 0;
            hf.bitlen[hf.tbl[0]] = 0;
            return true;
        }

/*
 * Make a huffman coding table.
 */
        public static bool lzh_make_huffman_table(huffman hf)
        {
            // uint16_t *tbl;
            // const unsigned char *bitlen;
            // int bitptn[17], weight[17];
            // int i, maxbits = 0, ptn, tbl_size, w;
            // int diffbits, len_avail;
            var bitptn = new int[17];
            var weight = new int[17];
            var maxbits = 0;
            var p = 0;

            /*
             * Initialize bit patterns.
             */
            var ptn = 0;
            var w = 1 << 15;
            for (var i = 1; i <= 16; i++, w >>= 1)
            {
                bitptn[i] = ptn;
                weight[i] = w;
                if (hf.freq[i] != 0)
                {
                    ptn += hf.freq[i] * w;
                    maxbits = i;
                }
            }

            if (ptn != 0x10000 || maxbits > hf.tbl_bits)
            {
                return false; /* Invalid */
            }

            hf.max_bits = maxbits;

            /*
             * Cut out extra bits which we won't house in the table.
             * This preparation reduces the same calculation in the for-loop
             * making the table.
             */
            if (maxbits < 16)
            {
                int ebits = 16 - maxbits;
                for (var i = 1; i <= maxbits; i++)
                {
                    bitptn[i] >>= ebits;
                    weight[i] >>= ebits;
                }
            }

            int diffbits;
            if (maxbits > Constants.HTBL_BITS)
            {
                //uint16_t *p;

                diffbits = maxbits - Constants.HTBL_BITS;
                for (var i = 1; i <= Constants.HTBL_BITS; i++)
                {
                    bitptn[i] >>= diffbits;
                    weight[i] >>= diffbits;
                }

                var htbl_max = bitptn[Constants.HTBL_BITS] +
                               weight[Constants.HTBL_BITS] * hf.freq[Constants.HTBL_BITS];
                //p = &(hf->tbl[htbl_max]);
                p = htbl_max;
                while (p < 1U << Constants.HTBL_BITS)
                {
                    //*p++ = 0;
                    hf.tbl[p++] = 0;
                }
            }
            else
                diffbits = 0;

            hf.shift_bits = diffbits;

            /*
             * Make the table.
             */
            var tbl_size = 1 << Constants.HTBL_BITS;
            var tbl = hf.tbl;
            var bitlen = hf.bitlen;
            var len_avail = hf.len_avail;
            hf.tree_used = 0;
            for (var i = 0; i < len_avail; i++)
            {
                // uint16_t *p;
                int len, cnt;
                //uint16_t bit;
                int extlen;
                //struct htree_t *ht;

                if (bitlen[i] == 0)
                    continue;
                /* Get a bit pattern */
                len = bitlen[i];
                ptn = bitptn[len];
                cnt = weight[len];
                if (len <= Constants.HTBL_BITS)
                {
                    /* Calculate next bit pattern */
                    if ((bitptn[len] = ptn + cnt) > tbl_size)
                        return false; /* Invalid */
                    /* Update the table */
                    //p = &(tbl[ptn]);
                    p = ptn;
                    if (cnt > 7)
                    {
                        //uint16_t *pc;

                        cnt -= 8;
                        //pc = &p[cnt];
                        var pc = p + cnt;
                        tbl[pc + 0] = (ushort)i;
                        tbl[pc + 1] = (ushort)i;
                        tbl[pc + 2] = (ushort)i;
                        tbl[pc + 3] = (ushort)i;
                        tbl[pc + 4] = (ushort)i;
                        tbl[pc + 5] = (ushort)i;
                        tbl[pc + 6] = (ushort)i;
                        tbl[pc + 7] = (ushort)i;
                        if (cnt > 7)
                        {
                            cnt -= 8;
                            //memcpy(&p[cnt], pc, 8 * sizeof(uint16_t));
                            Array.Copy(tbl, pc, tbl, p + cnt, 16);

                            //pc = &p[cnt];
                            pc = p + cnt;
                            while (cnt > 15)
                            {
                                cnt -= 16;
                                //memcpy(&p[cnt], pc, 16 * sizeof(uint16_t));
                                Array.Copy(tbl, pc, tbl, p + cnt, 16);
                            }
                        }

                        if (cnt != 0)
                        {
                            //memcpy(p, pc, cnt * sizeof(uint16_t));
                        }
                    }
                    else
                    {
                        while (cnt > 1)
                        {
                            tbl[p + --cnt] = (ushort)i;
                            tbl[p + --cnt] = (ushort)i;
                        }

                        if (cnt != 0)
                            tbl[p + --cnt] = (ushort)i;
                    }

                    continue;
                }

                /*
                 * A bit length is too big to be housed to a direct table,
                 * so we use a tree model for its extra bits.
                 */
                bitptn[len] = ptn + cnt;
                var bit = 1U << (diffbits - 1);
                extlen = len - Constants.HTBL_BITS;

                //p = &(tbl[ptn >> diffbits]);
                htree_t ht;
                p = ptn >> diffbits;
                if (p == 0)
                {
                    p = len_avail + hf.tree_used;
                    ht = hf.tree[hf.tree_used++];
                    if (hf.tree_used > hf.tree_avail)
                        return false; /* Invalid */
                    ht.left = 0;
                    ht.right = 0;
                }
                else
                {
                    if (p < len_avail || p >= (len_avail + hf.tree_used))
                        return false; /* Invalid */
                    ht = hf.tree[p - len_avail];
                }

                while (--extlen > 0)
                {
                    if ((ptn & bit) != 0)
                    {
                        if (ht.left < len_avail)
                        {
                            ht.left = (ushort)(len_avail + hf.tree_used);
                            ht = hf.tree[hf.tree_used++];
                            if (hf.tree_used > hf.tree_avail)
                                return false; /* Invalid */
                            ht.left = 0;
                            ht.right = 0;
                        }
                        else
                        {
                            ht = hf.tree[ht.left - len_avail];
                        }
                    }
                    else
                    {
                        if (ht.right < len_avail)
                        {
                            ht.right = (ushort)(len_avail + hf.tree_used);
                            ht = hf.tree[hf.tree_used++];
                            if (hf.tree_used > hf.tree_avail)
                                return false; /* Invalid */
                            ht.left = 0;
                            ht.right = 0;
                        }
                        else
                        {
                            ht = hf.tree[ht.right - len_avail];
                        }
                    }

                    bit >>= 1;
                }

                if ((ptn & bit) != 0)
                {
                    if (ht.left != 0)
                        return false; /* Invalid */
                    ht.left = (ushort)i;
                }
                else
                {
                    if (ht.right != 0)
                        return false; /* Invalid */
                    ht.right = (ushort)i;
                }
            }

            return true;
        }

        public static int lzh_decode_huffman_tree(huffman hf, int rbits, int c)
        {
            var ht = hf.tree;
            var extlen = hf.shift_bits;
            while (c >= hf.len_avail)
            {
                c -= hf.len_avail;
                if (extlen-- <= 0 || c >= hf.tree_used)
                    return 0;
                if ((rbits & (1U << extlen)) != 0)
                    c = ht[c].left;
                else
                    c = ht[c].right;
            }

            return c;
        }

        public static int lzh_decode_huffman(huffman hf, int rbits)
        {
            /*
             * At first search an index table for a bit pattern.
             * If it fails, search a huffman tree for.
             */
            var c = hf.tbl[rbits >> hf.shift_bits];
            if (c < hf.len_avail || hf.len_avail == 0)
                return c;
            /* This bit pattern needs to be found out at a huffman tree. */
            return lzh_decode_huffman_tree(hf, rbits, c);
        }
    }
}