namespace HstWbInstaller.Core.IO.Lha
{
    using System.IO;
    using System.Linq;

    public class LhExt
    {
        //private readonly Lha lha;
        private readonly bool verifyMode;
        private readonly bool textMode;
        private readonly bool extract_broken_archive;

        private readonly CrcIo crcIo;
        // https://github.com/jca02266/lha/blob/803fc759edd4786b7c775dea420792650934f922/src/lhext.c
        
        // https://github.com/jca02266/lha/blob/03475355bc6311f7f816ea9a88fb34a0029d975b/src/slide.c
        // static struct decode_option decode_define[] 
        private readonly IDecoder[] decoders = {
            new Lh1Decoder(),
            new Lh2Decoder(),
            new Lh3Decoder(),
            new Lh4Decoder(),
            new Lh5Decoder(),
            new Lh6Decoder(),
            new Lh7Decoder(),
            new LzsDecoder(),
            new Lz5Decoder(),
            new Lz4Decoder(),
            new LhdDecoder(),
            new Pm0Decoder(),
            new Pm2Decoder()
        };

        /*
static struct decode_option decode_define[] = {
    /* lh1
        {decode_c_dyn, decode_p_st0, decode_start_fix},
        /* lh2
        {decode_c_dyn, decode_p_dyn, decode_start_dyn},
        /* lh3
        {decode_c_st0, decode_p_st0, decode_start_st0},
        /* lh4
        {decode_c_st1, decode_p_st1, decode_start_st1},
        /* lh5
        {decode_c_st1, decode_p_st1, decode_start_st1},
        /* lh6
        {decode_c_st1, decode_p_st1, decode_start_st1},
        /* lh7
        {decode_c_st1, decode_p_st1, decode_start_st1},
        /* lzs
        {decode_c_lzs, decode_p_lzs, decode_start_lzs},
        /* lz5
        {decode_c_lz5, decode_p_lz5, decode_start_lz5},
        /* lz4
        {NULL        , NULL        , NULL            },
        /* lhd
        {NULL        , NULL        , NULL            },
        /* pm0
        {NULL        , NULL        , NULL            },
        /* pm2
        {decode_c_pm2, decode_p_pm2, decode_start_pm2}
    };
         */
        
        public LhExt(bool verifyMode = false, bool textMode = false, bool extractBrokenArchive = false)
        {
            this.verifyMode = verifyMode;
            this.textMode = textMode;
            this.crcIo = new CrcIo(verifyMode);
            this.extract_broken_archive = extractBrokenArchive;
        }

        private readonly string[] methods =
        {
            Constants.LZHUFF0_METHOD, Constants.LZHUFF1_METHOD, Constants.LZHUFF2_METHOD, Constants.LZHUFF3_METHOD,
            Constants.LZHUFF4_METHOD, Constants.LZHUFF5_METHOD, Constants.LZHUFF6_METHOD, Constants.LZHUFF7_METHOD,
            Constants.LARC_METHOD, Constants.LARC5_METHOD, Constants.LARC4_METHOD, Constants.LZHDIRS_METHOD,
            Constants.PMARC0_METHOD, Constants.PMARC2_METHOD
        };

        public void ExtractOne(Stream input, Stream output, LzHeader hdr)
        {
            // if (ignoreDirectory && hdr.Name.EndsWith("/"))
            // {
            //     q = (char *) strrchr(hdr->name, '/') + 1;
            // }
            // else {
            //     if (is_directory_traversal(q)) {
            //         error("Possible directory traversal hack attempt in %s", q);
            //         exit(1);
            //     }
            //
            //     if (*q == '/') {
            //         while (*q == '/') { q++; }
            //
            //         /*
            //          * if OSK then strip device name
            //          */
            //         if (hdr.ExtendType == Constants.EXTEND_OS68K || hdr.ExtendType == Constants.EXTEND_XOSK) {
            //             do
            //                 c = (*q++);
            //             while (c && c != '/');
            //             if (!c || !*q)
            //                 q = ".";    /* if device name only */
            //         }
            //     }
            // }
            
            var method = methods.FirstOrDefault(x => x == hdr.Method);

            if (string.IsNullOrWhiteSpace(method))
            {
                throw new IOException($"Unknown method \"{method}\"; \"{hdr.Name}\" will be skipped ...");
            }
            
            var crc = DecodeLzHuf(input, output, hdr, out var readSize);

            if (hdr.PackedSize != readSize)
            {
                throw new IOException($"Read size {readSize} doesnt match packed size {hdr.PackedSize}");
            }
            
            if (hdr.HasCrc && crc != hdr.Crc)
            {
                throw new IOException($"CRC error: \"{hdr.Name}\"");
            }
        }

        public uint DecodeLzHuf(Stream input, Stream output, LzHeader hdr, out int read_size)
        {
            read_size = 0;
            // https://github.com/jca02266/lha/blob/03475355bc6311f7f816ea9a88fb34a0029d975b/src/extract.c
            
            var method = hdr.Method switch
            {
                Constants.LZHUFF0_METHOD => /* -lh0- */ Constants.LZHUFF0_METHOD_NUM,
                Constants.LZHUFF1_METHOD => /* -lh1- */ Constants.LZHUFF1_METHOD_NUM,
                Constants.LZHUFF2_METHOD => /* -lh2- */ Constants.LZHUFF2_METHOD_NUM,
                Constants.LZHUFF3_METHOD => /* -lh2- */ Constants.LZHUFF3_METHOD_NUM,
                Constants.LZHUFF4_METHOD => /* -lh4- */ Constants.LZHUFF4_METHOD_NUM,
                Constants.LZHUFF5_METHOD => /* -lh5- */ Constants.LZHUFF5_METHOD_NUM,
                Constants.LZHUFF6_METHOD => /* -lh6- */ Constants.LZHUFF6_METHOD_NUM,
                Constants.LZHUFF7_METHOD => /* -lh7- */ Constants.LZHUFF7_METHOD_NUM,
                Constants.LARC_METHOD => /* -lzs- */ Constants.LARC_METHOD_NUM,
                Constants.LARC5_METHOD => /* -lz5- */ Constants.LARC5_METHOD_NUM,
                Constants.LARC4_METHOD => /* -lz4- */ Constants.LARC4_METHOD_NUM,
                Constants.PMARC0_METHOD => /* -pm0- */ Constants.PMARC0_METHOD_NUM,
                Constants.PMARC2_METHOD => /* -pm2- */ Constants.PMARC2_METHOD_NUM,
                _ => Constants.LZHUFF5_METHOD_NUM
            };
            
            var dicbit = hdr.Method switch
            {
                Constants.LZHUFF0_METHOD => /* -lh0- */ Constants.LZHUFF0_DICBIT,
                Constants.LZHUFF1_METHOD => /* -lh1- */ Constants.LZHUFF1_DICBIT,
                Constants.LZHUFF2_METHOD => /* -lh2- */ Constants.LZHUFF2_DICBIT,
                Constants.LZHUFF3_METHOD => /* -lh2- */ Constants.LZHUFF3_DICBIT,
                Constants.LZHUFF4_METHOD => /* -lh4- */ Constants.LZHUFF4_DICBIT,
                Constants.LZHUFF5_METHOD => /* -lh5- */ Constants.LZHUFF5_DICBIT,
                Constants.LZHUFF6_METHOD => /* -lh6- */ Constants.LZHUFF6_DICBIT,
                Constants.LZHUFF7_METHOD => /* -lh7- */ Constants.LZHUFF7_DICBIT,
                Constants.LARC_METHOD => /* -lzs- */ Constants.LARC_DICBIT,
                Constants.LARC5_METHOD => /* -lz5- */ Constants.LARC5_DICBIT,
                Constants.LARC4_METHOD => /* -lz4- */ Constants.LARC4_DICBIT,
                Constants.PMARC0_METHOD => /* -pm0- */ Constants.PMARC0_DICBIT,
                Constants.PMARC2_METHOD => /* -pm2- */ Constants.PMARC2_DICBIT,
                _ => Constants.LZHUFF5_DICBIT
            };

            // reset crc
            crcIo.InitializeCrc();

            if (dicbit == 0)
            {
                /* LZHUFF0_DICBIT or LARC4_DICBIT or PMARC0_DICBIT*/
                // *read_sizep = copyfile(infp, (verify_mode ? NULL : outfp), original_size, 2, &crc);
                read_size = Util.CopyFile(input, verifyMode ? null : output, (int)hdr.OriginalSize, textMode, crcIo);
            }
            else
            {
                read_size = Decode(input, output, method, dicbit, (int)hdr.OriginalSize, (int)hdr.PackedSize);
                //read_size =  interface.read_size;
            }

            return crcIo.crc;
        }

        private int Decode(Stream input, Stream output, int method, int dicbit, int origsize, int packed)
        {
            // infile = interface->infile;
            // outfile = interface->outfile;
            // dicbit = interface->dicbit;
            // origsize = interface->original;
            // compsize = interface->packed;
            // decode_set = decode_define[interface->method - 1];
            var decode_set = decoders[method - 1];

            var bitIo = new BitIo(input, origsize, packed);
            var huf = new Huf(dicbit, bitIo, crcIo);
            
            //uint i, c;
            //uint dicsiz1, adjust;
            
            // https://github.com/jca02266/lha/blob/master/src/slide.c
            //crcIo.InitializeCrc();
            var dicsiz = 1L << dicbit;
            // dtext = (unsigned char *)xmalloc(dicsiz);
            var dtext = new byte[dicsiz];

            for (var i = 0; i < dicsiz; i++)
            {
                dtext[i] = (byte)(extract_broken_archive ? 0 : ' ');
            }

            decode_set.DecodeStart(huf);
            var dicsiz1 = dicsiz - 1;
            var adjust = 256 - Constants.THRESHOLD;
            if (method == Constants.LARC_METHOD_NUM || method == Constants.PMARC2_METHOD_NUM)
            {
                adjust = 256 - 2;
            }
            
            var decode_count = 0;
            var loc = 0;
            ushort c;
            while (decode_count < origsize) {
                c = decode_set.DecodeC(huf);
                if (c < 256) {
                    dtext[loc++] = (byte)c;
                    if (loc == dicsiz) {
                        crcIo.fwrite_crc(dtext, (int)dicsiz, output);
                        loc = 0;
                    }
                    decode_count++;
                }
                else {
                    // struct matchdata match;
                    // unsigned int matchpos;
                    int matchdata_len;
                    uint matchdata_off;
                    uint matchpos;

                    matchdata_len = c - adjust;
                    matchdata_off = (uint)decode_set.DecodeP(huf) + 1;
                    matchpos = (uint)((loc - matchdata_off) & dicsiz1);

                    decode_count += matchdata_len;
                    for (var i = 0; i < matchdata_len; i++) {
                        c = dtext[(matchpos + i) & dicsiz1];
                        dtext[loc++] = (byte)c;
                        if (loc == dicsiz) {
                            crcIo.fwrite_crc(dtext, (int)dicsiz, output);
                            loc = 0;
                        }
                    }
                }
            }
            if (loc != 0) {
                crcIo.fwrite_crc(dtext, loc, output);
            }

            /* usually read size is interface->packed */
            //interface->read_size = interface->packed - compsize;
            //read_size = interface->packed - compsize;

            return packed - bitIo.compsize;            
        }
    }
}