// namespace HstWbInstaller.Core.IO.Lha
// {
//     using System;
//     using System.IO;
//     using System.Linq;
//     using System.Threading.Tasks;
//
//     public static class LhaExtractor
//     {
//         public static string[] methods =
//         {
//             Constants.LZHUFF0_METHOD, Constants.LZHUFF1_METHOD, Constants.LZHUFF2_METHOD, Constants.LZHUFF3_METHOD,
//             Constants.LZHUFF4_METHOD, Constants.LZHUFF5_METHOD, Constants.LZHUFF6_METHOD, Constants.LZHUFF7_METHOD,
//             Constants.LARC_METHOD, Constants.LARC5_METHOD, Constants.LARC4_METHOD,
//             Constants.LZHDIRS_METHOD,
//             Constants.PMARC0_METHOD, Constants.PMARC2_METHOD
//         };
//
//
//         public static async Task ExtractOne(Stream stream, LzHeader header)
//         {
//             var method = methods.FirstOrDefault(x => x == header.Method);
//
//             if (string.IsNullOrWhiteSpace(method))
//             {
//                 throw new IOException($"Unknown method \"{method}\"; \"{header.Name}\" will be skipped ...");
//             }
//
//
//             // crc = decode_lzhuf(afp, stdout,
//             //     hdr->original_size, hdr->packed_size,
//             //     name, method, &read_size);
//
//
//             if (header.HasCrc && crc != header.Crc)
//             {
//                 throw new IOException($"CRC error: \"{header.Name}\"");
//             }
//         }
//
//         public static int DecodeLzHuf(string method)
//         {
//             var dicbit = method switch
//             {
//                 Constants.LZHUFF0_METHOD => /* -lh0- */ Constants.LZHUFF0_DICBIT,
//                 Constants.LZHUFF1_METHOD => /* -lh1- */ Constants.LZHUFF1_DICBIT,
//                 Constants.LZHUFF2_METHOD => /* -lh2- */ Constants.LZHUFF2_DICBIT,
//                 Constants.LZHUFF3_METHOD => /* -lh2- */ Constants.LZHUFF3_DICBIT,
//                 Constants.LZHUFF4_METHOD => /* -lh4- */ Constants.LZHUFF4_DICBIT,
//                 Constants.LZHUFF5_METHOD => /* -lh5- */ Constants.LZHUFF5_DICBIT,
//                 Constants.LZHUFF6_METHOD => /* -lh6- */ Constants.LZHUFF6_DICBIT,
//                 Constants.LZHUFF7_METHOD => /* -lh7- */ Constants.LZHUFF7_DICBIT,
//                 Constants.LARC_METHOD => /* -lzs- */ Constants.LARC_DICBIT,
//                 Constants.LARC5_METHOD => /* -lz5- */ Constants.LARC5_DICBIT,
//                 Constants.LARC4_METHOD => /* -lz4- */ Constants.LARC4_DICBIT,
//                 Constants.PMARC0_METHOD => /* -pm0- */ Constants.PMARC0_DICBIT,
//                 Constants.PMARC2_METHOD => /* -pm2- */ Constants.PMARC2_DICBIT,
//                 _ => Constants.LZHUFF5_DICBIT
//             };
//
//             int crc = 0;
//             if (dicbit == 0)
//             {
//                 /* LZHUFF0_DICBIT or LARC4_DICBIT or PMARC0_DICBIT*/
//                 //*read_sizep = copyfile(infp, (verify_mode ? NULL : outfp),
//                 //    original_size, 2, &crc);
//             }
//             else
//             {
//                 crc = Decode(dicbit);
//                 //*read_sizep = interface.read_size;
//             }
//
//             return crc;
//         }
//
//         // https://github.com/jca02266/lha/blob/master/src/slide.c
//         private static int Decode(int dicbit)
//         {
//             var crc = CrcHelper.InitializeCrc();
//             var dicsiz = 1L << dicbit;
//             var dtext = new byte[dicsiz];
//         }
//     }
//
//     public interface IDecoder
//     {
//         short DecodeC();
//         short DecodeP();
//         void DecodeStart();
//     }
//
//     public class Lh1Decoder : IDecoder
//     {
//         // https://github.com/jca02266/lha/blob/master/src/slide.c
//         /* lh1 */
//         //{decode_c_dyn, decode_p_st0, decode_start_fix},
//         public short DecodeC()
//         {
//             throw new System.NotImplementedException();
//         }
//
//         public short DecodeP()
//         {
//             throw new System.NotImplementedException();
//         }
//
//         public void DecodeStart()
//         {
//             throw new System.NotImplementedException();
//         }
//     }
//
//     public static class Lh2Decoder
//     {
//         // https://github.com/jca02266/lha/blob/master/src/slide.c
//         /* lh2 */
//         //{decode_c_dyn, decode_p_dyn, decode_start_dyn},
//     }
//
//     public static class Lh3Decoder
//     {
//         // https://github.com/jca02266/lha/blob/master/src/slide.c
//         /* lh3 */
//         //{decode_c_st0, decode_p_st0, decode_start_st0},
//     }
//
//     public static class Lh4Decoder
//     {
//         // https://github.com/jca02266/lha/blob/master/src/slide.c
//         /* lh4 */
//         //{decode_c_st1, decode_p_st1, decode_start_st1},
//     }
//
//     public static class Lh5Decoder
//     {
//         // https://github.com/jca02266/lha/blob/master/src/slide.c
//         /* lh4 */
//         //{decode_c_st1, decode_p_st1, decode_start_st1},
//     }
//
//     public class BitIo
//     {
//         // https://github.com/jca02266/lha/blob/03475355bc6311f7f816ea9a88fb34a0029d975b/src/bitio.c
//
//         private readonly Stream stream;
//         private int compsize;
//         private ushort bitbuf;
//         private int subbitbuf, bitcount;
//
//         public BitIo(Stream stream)
//         {
//             this.stream = stream;
//             this.compsize = 0;
//             this.bitbuf = 0;
//             this.subbitbuf = 0;
//             this.bitcount = 0;
//         }
//
//         public void FillBuf(int n)
//         {
//             while (n > bitcount)
//             {
//                 n -= bitcount;
//                 bitbuf = (bitbuf << bitcount) + (subbitbuf >> (CrcHelper.CHAR_BIT - bitcount));
//                 if (compsize != 0)
//                 {
//                     compsize--;
//                     var c = stream.ReadByte();
//                     if (c == -1)
//                     {
//                         throw new IOException("cannot read stream");
//                     }
//
//                     subbitbuf = (byte)c;
//                 }
//                 else
//                     subbitbuf = 0;
//
//                 bitcount = CrcHelper.CHAR_BIT;
//             }
//
//             bitcount -= n;
//             bitbuf = (bitbuf << n) + (subbitbuf >> (CrcHelper.CHAR_BIT - n));
//             subbitbuf <<= n;
//         }
//
//         public int GetBits(int n)
//         {
//             var x = bitbuf >> (2 * CrcHelper.CHAR_BIT - n);
//             FillBuf(n);
//             return x;
//         }
//
//         private const byte SIZE_BITBUF = 2;
//
//         public int PeekBits(int n)
//         {
//             return (bitbuf >> (SIZE_BITBUF * 8 - (n)));
//         }
//     }
//
//     public class Huf
//     {
//         private readonly BitIo bitIo;
//         private readonly byte[] c_len;
//         private readonly byte[] pt_len;
//
//         private readonly ushort[] c_table; /* decode */
//         private readonly ushort[] pt_table; /* decode */
//
//         private readonly byte[] left;
//         private readonly byte[] right;
//
//         public Huf(Stream stream)
//         {
//             bitIo = new BitIo(stream);
//             c_len = new byte[Constants.NC];
//             pt_len = new byte[Constants.NPT];
//             c_table = new ushort[4096];
//             pt_table = new ushort[256];
//             left = new byte[2 * Constants.NC - 1];
//             right = new byte[2 * Constants.NC - 1];
//         }
//
//         public void ReadPtLen(short nn, short nbit, short i_special)
//         {
//             // https://github.com/jca02266/lha/blob/03475355bc6311f7f816ea9a88fb34a0029d975b/src/huf.c#L324
//
//             var c = 0;
//             var n = bitIo.GetBits(nbit);
//             if (n == 0)
//             {
//                 c = bitIo.GetBits(nbit);
//                 for (var i = 0; i < nn; i++)
//                 {
//                     pt_len[i] = 0;
//                 }
//
//                 for (var i = 0; i < 256; i++)
//                 {
//                     pt_table[i] = c;
//                 }
//             }
//             else
//             {
//                 var i = 0;
//                 while (i < Math.Min(n, Constants.NPT))
//                 {
//                     c = bitIo.PeekBits(3);
//                     if (c != 7)
//                         bitIo.FillBuf(3);
//                     else
//                     {
//                         ushort mask = 1 << (16 - 4);
//                         while (mask & bitbuf)
//                         {
//                             mask >>= 1;
//                             c++;
//                         }
//
//                         bitIo.FillBuf(c - 3);
//                     }
//
//                     pt_len[i++] = c;
//                     if (i == i_special)
//                     {
//                         c = bitIo.GetBits(2);
//                         while (--c >= 0 && i < Constants.NPT)
//                             pt_len[i++] = 0;
//                     }
//                 }
//
//                 while (i < nn)
//                     pt_len[i++] = 0;
//                 MakeTable(nn, pt_len, 8, pt_table);
//             }
//         }
//
//         public int decode_c_st1(int blocksize)
//         {
//             // https://github.com/jca02266/lha/blob/03475355bc6311f7f816ea9a88fb34a0029d975b/src/huf.c
//             ushort j = 0;
//             ushort mask = 0;
//
//             if (blocksize == 0)
//             {
//                 blocksize = bitIo.GetBits(16);
//                 ReadPtLen(Constants.NT, Constants.TBIT, 3);
//                 read_c_len();
//                 ReadPtLen(np, pbit, -1);
//             }
//
//             blocksize--;
//             j = c_table[bitIo.PeekBits(12)];
//             if (j < Constants.NC)
//                 bitIo.FillBuf(c_len[j]);
//             else
//             {
//                 bitIo.FillBuf(12);
//                 mask = 1 << (16 - 1);
//                 do
//                 {
//                     if (bitbuf & mask)
//                         j = right[j];
//                     else
//                         j = left[j];
//                     mask >>= 1;
//                 } while (j >= Constants.NC && (mask != 0 || j != left[j])); /* CVE-2006-4338 */
//
//                 bitIo.FillBuf(c_len[j] - 12);
//             }
//
//             return j;
//         }
//
//         private void MakeTable(short nchar, byte[] bitlen, byte tablebits, ushort[] table)
//         {
//             // https://github.com/jca02266/lha/blob/03475355bc6311f7f816ea9a88fb34a0029d975b/src/maketbl.c
//
//             var count = new ushort[17];
//             var weight = new ushort[17];
//             var start = new ushort[17];
//
//             var avail = nchar;
//
//             /* initialize */
//             for (var i = 1; i <= 16; i++)
//             {
//                 count[i] = 0;
//                 weight[i] = (ushort)(1 << (16 - i));
//             }
//
//             /* count */
//             for (var i = 0; i < nchar; i++)
//             {
//                 if (bitlen[i] > 16)
//                 {
//                     /* CVE-2006-4335 */
//                     throw new Exception("Bad table (case a)");
//                 }
//                 else
//                 {
//                     count[bitlen[i]]++;
//                 }
//             }
//
//             /* calculate first code */
//             var total = 0;
//             for (var i = 1; i <= 16; i++)
//             {
//                 start[i] = (ushort)total;
//                 total += weight[i] * count[i];
//             }
//
//             if ((total & 0xffff) != 0 || tablebits > 16)
//             {
//                 /* 16 for weight below */
//                 throw new Exception("make_table(): Bad table (case b)");
//             }
//
//             /* shift data for make table. */
//             var m = 16 - tablebits;
//             for (var i = 1; i <= tablebits; i++)
//             {
//                 start[i] >>= m;
//                 weight[i] >>= m;
//             }
//
//             /* initialize */
//             var j = start[tablebits + 1] >> m;
//             var k = Math.Min(1 << tablebits, 4096);
//             if (j != 0)
//                 for (var i = j; i < k; i++)
//                     table[i] = 0;
//
// /* create table and tree */
//             for (j = 0; j < nchar; j++)
//             {
//                 k = bitlen[j];
//                 if (k == 0)
//                     continue;
//                 var l = start[k] + weight[k];
//                 if (k <= tablebits)
//                 {
//                     /* code in table */
//                     l = Math.Min(l, 4096);
//                     for (var i = start[k]; i < l; i++)
//                         table[i] = j;
//                 }
//                 else
//                 {
//                     /* code not in table */
//                     var i = start[k];
//                     if ((i >> m) > 4096)
//                     {
//                         /* CVE-2006-4337 */
//                         error("Bad table (case c)");
//                         exit(1);
//                     }
//
//                     var p = table[i >> m];
//                     i <<= tablebits;
//                     var n = k - tablebits;
//                     /* make tree (n length) */
//                     while (--n >= 0)
//                     {
//                         if (*p == 0)
//                         {
//                             right[avail] = left[avail] = 0;
//                             *p = avail++;
//                         }
//
//                         if (i & 0x8000)
//                             p = &right[*p];
//                         else
//                             p = &left[*p];
//                         i <<= 1;
//                     }
//
//                     *p = j;
//                 }
//
//                 start[k] = l;
//             }
//         }
//     }
// }