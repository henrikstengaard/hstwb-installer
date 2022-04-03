namespace HstWbInstaller.Core.IO.Lha
{
    using System;
    using System.IO;

    public class Huf
    {
        private const int N1 = 286;             /* alphabet size */
        private const int N2 = 2 * N1 - 1;    /* # of nodes in Huffman tree */        
        private const int NP = 8 * 1024 / 64;
        private const int NP2 = NP * 2 - 1;
        
        //private uint np;
        private int[][] fixedTable = {
            new [] {3, 0x01, 0x04, 0x0c, 0x18, 0x30, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},   /* old compatible */
            new [] {2, 0x01, 0x01, 0x03, 0x06, 0x0D, 0x1F, 0x4E, 0, 0, 0, 0, 0, 0, 0, 0}    /* 8K buf */
        };        
        private readonly Lha lha;

        // https://github.com/jca02266/lha/blob/03475355bc6311f7f816ea9a88fb34a0029d975b/src/huf.c
        private readonly BitIo bitIo;
        private readonly CrcIo crcIo;
        
        // unsigned short left[2 * NC - 1], right[2 * NC - 1];
        private readonly ushort[] left;
        private readonly ushort[] right;

        // unsigned short c_code[NC];      /* encode */
        // unsigned short pt_code[NPT];    /* encode */
        private readonly ushort[] c_code; /* encode */
        private readonly ushort[] pt_code; /* encode */

        // unsigned short c_table[4096];   /* decode */
        // unsigned short pt_table[256];   /* decode */
        private readonly ushort[] c_table; /* decode */
        private readonly ushort[] pt_table; /* decode */
        
        // unsigned short c_freq[2 * NC - 1]; /* encode */
        // unsigned short p_freq[2 * NP - 1]; /* encode */
        // unsigned short t_freq[2 * NT - 1]; /* encode */
        private readonly ushort[] c_freq; /* encode */
        private readonly ushort[] p_freq; /* encode */
        private readonly ushort[] t_freq; /* encode */

        // unsigned char  c_len[NC];
        // unsigned char  pt_len[NPT];
        private readonly byte[] c_len;
        private readonly byte[] pt_len;

        // static unsigned char *buf;      /* encode */
        // static unsigned int bufsiz;     /* encode */
        // static unsigned short blocksize; /* decode */
        // static unsigned short output_pos, output_mask; /* encode */
        public byte buf;      /* encode */
        public uint bufsiz;     /* encode */
        static ushort blocksize; /* decode */
        //static ushort output_pos, output_mask; /* encode */

        // static int pbit;
        // static int np;
        public int pbit;
        public int np;
        
        public Huf(Stream stream, Lha lha, int origsize, int compsize)
        {
            this.lha = lha;
            bitIo = new BitIo(stream, origsize, compsize);
            crcIo = new CrcIo(lha);
            
            left = new ushort[2 * Constants.NC - 1];
            right = new ushort[2 * Constants.NC - 1];

            c_code = new ushort[Constants.NC];
            pt_code = new ushort[Constants.NPT];

            c_table = new ushort[4096];
            pt_table = new ushort[256];

            c_freq = new ushort[2 * Constants.NC - 1];
            p_freq = new ushort[2 * Constants.NP - 1];
            t_freq = new ushort[2 * Constants.NT - 1];
            
            c_len = new byte[Constants.NC];
            pt_len = new byte[Constants.NPT];
        }
        
        // encode parts are skipped

        public void ReadPtLen(short nn, short nbit, short i_special)
        {
            // https://github.com/jca02266/lha/blob/03475355bc6311f7f816ea9a88fb34a0029d975b/src/huf.c#L324

            var c = 0;
            var n = bitIo.GetBits(nbit);
            if (n == 0)
            {
                c = bitIo.GetBits(nbit);
                for (var i = 0; i < nn; i++)
                {
                    pt_len[i] = 0;
                }

                for (var i = 0; i < 256; i++)
                {
                    pt_table[i] = (ushort)c;
                }
            }
            else
            {
                var i = 0;
                while (i < Math.Min(n, Constants.NPT))
                {
                    c = bitIo.PeekBits(3);
                    if (c != 7)
                        bitIo.FillBuf(3);
                    else
                    {
                        ushort mask = 1 << (16 - 4);
                        while ((mask & bitIo.bitbuf) != 0)
                        {
                            mask >>= 1;
                            c++;
                        }

                        bitIo.FillBuf(c - 3);
                    }

                    pt_len[i++] = (byte)c;
                    if (i == i_special)
                    {
                        c = bitIo.GetBits(2);
                        while (--c >= 0 && i < Constants.NPT)
                            pt_len[i++] = 0;
                    }
                }

                while (i < nn)
                    pt_len[i++] = 0;
                MakeTable(nn, pt_len, 8, pt_table);
            }
        }
        
        public void ReadCLen()
        {
            short i, c, n;

            n = (short)bitIo.GetBits(Constants.CBIT);
            if (n == 0) {
                c = (short)bitIo.GetBits(Constants.CBIT);
                for (i = 0; i < Constants.NC; i++)
                    c_len[i] = 0;
                for (i = 0; i < 4096; i++)
                    c_table[i] = (ushort)c;
            } else {
                i = 0;
                while (i < Math.Min(n, Constants.NC)) {
                    c = (short)pt_table[bitIo.PeekBits(8)];
                    if (c >= Constants.NT) {
                        ushort mask = 1 << (16 - 9);
                        do {
                            if ((bitIo.bitbuf & mask) != 0)
                                c = (short)right[c];
                            else
                                c = (short)left[c];
                            mask >>= 1;
                        } while (c >= Constants.NT && (mask != 0 || c != left[c])); /* CVE-2006-4338 */
                    }
                    bitIo.FillBuf(pt_len[c]);
                    if (c <= 2) {
                        if (c == 0)
                            c = 1;
                        else if (c == 1)
                            c = (short)(bitIo.GetBits(4) + 3);
                        else
                            c = (short)(bitIo.GetBits(Constants.CBIT) + 20);
                        while (--c >= 0)
                            c_len[i++] = 0;
                    }
                    else
                        c_len[i++] = (byte)(c - 2);
                }
                while (i < Constants.NC)
                    c_len[i++] = 0;
                MakeTable(Constants.NC, c_len, 12, c_table);
            }
        }
        
        /* lh3 */
        public ushort decode_c_st0()
        {
            int i, j;
            //ushort blocksize = 0;

            if (blocksize == 0) {   /* read block head */
                blocksize = (ushort)bitIo.GetBits(Constants.BUFBITS);   /* read block blocksize */
                read_tree_c();
                if (bitIo.GetBits(1) != 0) {
                    read_tree_p();
                }
                else {
                    ready_made(1);
                }
                MakeTable(NP, pt_len, 8, pt_table);
            }
            blocksize--;
            j = c_table[bitIo.PeekBits(12)];
            if (j < N1)
                bitIo.FillBuf(c_len[j]);
            else {
                bitIo.FillBuf(12);
                i = bitIo.bitbuf;
                do {
                    if ((short) i < 0)
                        j = right[j];
                    else
                        j = left[j];
                    i <<= 1;
                } while (j >= N1);
                bitIo.FillBuf(c_len[j] - 12);
            }
            if (j == N1 - 1)
                j += bitIo.PeekBits(Constants.EXTRABITS);
            return (ushort)j;
        }

        /* ------------------------------------------------------------------------ */
        /* lh1, 3 */
        public ushort decode_p_st0()
        {
            // https://github.com/jca02266/lha/blob/03475355bc6311f7f816ea9a88fb34a0029d975b/src/shuf.c
            int i, j;

            j = pt_table[bitIo.PeekBits(8)];
            if (j < np) {
                bitIo.FillBuf(pt_len[j]);
            }
            else {
                bitIo.FillBuf(8);
                i = bitIo.bitbuf;
                do {
                    if ((short) i < 0)
                        j = right[j];
                    else
                        j = left[j];
                    i <<= 1;
                } while (j >= np);
                bitIo.FillBuf(pt_len[j] - 8);
            }
            return (ushort)((j << 6) + bitIo.GetBits(6));
        }
        
        public ushort decode_c_st1()
        {
            // https://github.com/jca02266/lha/blob/03475355bc6311f7f816ea9a88fb34a0029d975b/src/huf.c
            ushort j = 0;
            ushort mask = 0;

            if (blocksize == 0)
            {
                blocksize = (ushort)bitIo.GetBits(16);
                ReadPtLen(Constants.NT, Constants.TBIT, 3);
                ReadCLen();
                ReadPtLen((short)np, (short)pbit, -1);
            }

            blocksize--;
            j = c_table[bitIo.PeekBits(12)];
            if (j < Constants.NC)
                bitIo.FillBuf(c_len[j]);
            else
            {
                bitIo.FillBuf(12);
                mask = 1 << (16 - 1);
                do
                {
                    if ((bitIo.bitbuf & mask) != 0)
                        j = right[j];
                    else
                        j = left[j];
                    mask >>= 1;
                } while (j >= Constants.NC && (mask != 0 || j != left[j])); /* CVE-2006-4338 */

                bitIo.FillBuf(c_len[j] - 12);
            }

            return j;
        }
        
        /* ------------------------------------------------------------------------ */
        /* lh4, 5, 6, 7 */
        public ushort decode_p_st1( /* void */ )
        {
            ushort j, mask;

            j = pt_table[bitIo.PeekBits(8)];
            if (j < np)
                bitIo.FillBuf(pt_len[j]);
            else {
                bitIo.FillBuf(8);
                mask = 1 << (16 - 1);
                do {
                    if ((bitIo.bitbuf & mask) != 0)
                        j = right[j];
                    else
                        j = left[j];
                    mask >>= 1;
                } while (j >= np && (mask != 0 || j != left[j])); /* CVE-2006-4338 */
                bitIo.FillBuf(pt_len[j] - 8);
            }
            if (j != 0)
                j = (ushort)((1 << (j - 1)) + bitIo.GetBits(j - 1));
            return j;
        }

        /* ------------------------------------------------------------------------ */
        /* lh4, 5, 6, 7 */
        public void decode_start_st1()
        {
            switch (lha.dicbit) {
                case Constants.LZHUFF4_DICBIT:
                case Constants.LZHUFF5_DICBIT: pbit = 4; np = Constants.LZHUFF5_DICBIT + 1; break;
                case Constants.LZHUFF6_DICBIT: pbit = 5; np = Constants.LZHUFF6_DICBIT + 1; break;
                case Constants.LZHUFF7_DICBIT: pbit = 5; np = Constants.LZHUFF7_DICBIT + 1; break;
                default:
                    throw new Exception($"Cannot use {(1 << lha.dicbit)} bytes dictionary");
            }

            bitIo.InitGetBits();
            crcIo.init_code_cache();
            blocksize = 0;
        }

        private void MakeTable(short nchar, byte[] bitlen, byte tablebits, ushort[] table)
        {
            // https://github.com/jca02266/lha/blob/03475355bc6311f7f816ea9a88fb34a0029d975b/src/maketbl.c

            var count = new ushort[17];
            var weight = new ushort[17];
            var start = new ushort[17];

            var avail = nchar;

            /* initialize */
            for (var i = 1; i <= 16; i++)
            {
                count[i] = 0;
                weight[i] = (ushort)(1 << (16 - i));
            }

            /* count */
            for (var i = 0; i < nchar; i++)
            {
                if (bitlen[i] > 16)
                {
                    /* CVE-2006-4335 */
                    throw new Exception("Bad table (case a)");
                }
                else
                {
                    count[bitlen[i]]++;
                }
            }

            /* calculate first code */
            var total = 0;
            for (var i = 1; i <= 16; i++)
            {
                start[i] = (ushort)total;
                total += (ushort)(weight[i] * count[i]);
            }

            if ((total & 0xffff) != 0 || tablebits > 16)
            {
                /* 16 for weight below */
                throw new Exception("make_table(): Bad table (case b)");
            }

            /* shift data for make table. */
            var m = 16 - tablebits;
            for (var i = 1; i <= tablebits; i++)
            {
                start[i] >>= m;
                weight[i] >>= m;
            }

            /* initialize */
            var j = start[tablebits + 1] >> m;
            var k = Math.Min(1 << tablebits, 4096);
            if (j != 0)
                for (var i = j; i < k; i++)
                    table[i] = 0;

            /* create table and tree */
            for (j = 0; j < nchar; j++)
            {
                k = bitlen[j];
                if (k == 0)
                    continue;
                var l = start[k] + weight[k];
                if (k <= tablebits)
                {
                    /* code in table */
                    l = Math.Min(l, 4096);
                    for (var i = start[k]; i < l; i++)
                        table[i] = (ushort)j;
                }
                else
                {
                    /* code not in table */
                    var i = start[k];
                    if ((i >> m) > 4096)
                    {
                        /* CVE-2006-4337 */
                        throw new Exception("Bad table (case c)");
                    }

                    // unsigned short *p;
                    // p = &table[i >> m]; // p points to element (i >> m) in table array
                    var p = i >> m; // pointer to offset i >> m in array
                    
                    // *p: table[i >> m]
                    // c: p = &right[*p] -> c#: p = right[table[p]]
                    
                    i <<= tablebits;
                    var n = k - tablebits;
                    /* make tree (n length) */
                    while (--n >= 0)
                    {
                        // if (*p == 0) {
                        if (table[p] == 0) 
                        {
                            right[avail] = left[avail] = 0;
                            // *p = avail++;
                            table[p] = (ushort)(avail++);
                        }

                        if ((i & 0x8000) != 0)
                            // p = &right[*p];
                            p = right[table[p]];
                        else
                            // p = &left[*p];
                            p = left[table[p]];
                        i <<= 1;
                    }

                    //*p = j;
                    table[p] = (ushort)j;
                }

                start[k] = (ushort)l;
            }
        }
        
        public void read_tree_c()
        {
            /* read tree from file */
            int i, c;

            i = 0;
            while (i < N1) {
                if (bitIo.GetBits(1) != 0)
                    c_len[i] = (byte)(bitIo.GetBits(Constants.LENFIELD) + 1);
                else
                    c_len[i] = 0;
                if (++i == 3 && c_len[0] == 1 && c_len[1] == 1 && c_len[2] == 1) {
                    c = bitIo.GetBits(Constants.CBIT);
                    for (i = 0; i < N1; i++)
                        c_len[i] = 0;
                    for (i = 0; i < 4096; i++)
                        c_table[i] = (byte)c;
                    return;
                }
            }
            MakeTable(N1, c_len, 12, c_table);
        }
        
/* ------------------------------------------------------------------------ */
        public void read_tree_p()
        {
            /* read tree from file */
            int i, c;

            i = 0;
            while (i < NP) {
                pt_len[i] = (byte)bitIo.GetBits(Constants.LENFIELD);
                if (++i == 3 && pt_len[0] == 1 && pt_len[1] == 1 && pt_len[2] == 1) {
                    c = bitIo.GetBits(Constants.LZHUFF3_DICBIT - 6);
                    for (i = 0; i < NP; i++)
                        pt_len[i] = 0;
                    for (i = 0; i < 256; i++)
                        pt_table[i] = (ushort)c;
                    return;
                }
            }
        }
        
        public  void ready_made(int method)
        {
            // int             i, j;
            // unsigned int    code, weight;
            // int            *tbl;
            int i, j;
            uint code, weight;

            // tbl = fixed[method];
            var tbl = 0;
            j = fixedTable[method][tbl++];
            weight = (uint)(1 << (16 - j));
            code = 0;
            for (i = 0; i < np; i++) {
                while (fixedTable[method][tbl] == i) {
                    j++;
                    tbl++;
                    weight >>= 1;
                }
                pt_len[i] = (byte)j;
                pt_code[i] = (ushort)code;
                code += weight;
            }
        }        
    }
}