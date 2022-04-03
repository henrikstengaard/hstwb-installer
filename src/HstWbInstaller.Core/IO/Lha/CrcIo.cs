namespace HstWbInstaller.Core.IO.Lha
{
    using System.IO;

    public class CrcIo
    {
        private readonly Lha lha;
        // https://github.com/jca02266/lha/blob/03475355bc6311f7f816ea9a88fb34a0029d975b/src/crcio.c

        private const int EOF = -1;
        public uint crc;

        private uint[] crctable;
        //private int dispflg;

        public CrcIo(Lha lha)
        {
            this.lha = lha;
            crc = 0;
            crctable = new uint[Constants.UCHAR_MAX + 1];
        }
        
#if EUC
        private int putc_euc_cache;
#endif
        private int getc_euc_cache;        
        
        public void init_code_cache()
        {               /* called from copyfile() in util.c */
#if EUC
            putc_euc_cache = EOF;
#endif
            getc_euc_cache = EOF;
        }

        public uint InitializeCrc()
        {
            return crc = 0;
        }

        public void UPDATE_CRC(byte c)
        {
            //(crctable[((crc) ^ (unsigned char)(c)) & 0xFF] ^ ((crc) >> CHAR_BIT))   
            crc = crctable[(crc ^ c) & 0xFF] ^ crc >> Constants.CHAR_BIT;
        } 
        
        public int fread_txt(byte[] vp, int n, Stream stream)
        {
            // void *vp;
            // int  n;
            // FILE *fp;
            int             c;
            int             cnt = 0;
            // unsigned char *p;
            //p = vp;
            var p = 0;

            while (cnt < n) {
                if (getc_euc_cache != EOF) {
                    c = getc_euc_cache;
                    getc_euc_cache = EOF;
                }
                else {
                    // if ((c = fgetc(fp)) == EOF)
                    if ((c = stream.ReadByte()) == EOF)
                        break;
                    if (c == '\n') {
                        getc_euc_cache = c;
                        ++lha.origsize;
                        c = '\r';
                    }
#if EUC
                    else if (euc_mode && (c == 0x8E || (0xA0 < c && c < 0xFF))) {
                        int             d = fgetc(fp);
                        if (d == EOF) {
                            *p++ = c;
                            cnt++;
                            break;
                        }
                        if (c == 0x8E) {    /* single shift (KANA) */
                            if ((0x20 < d && d < 0x7F) || (0xA0 < d && d < 0xFF))
                                c = d | 0x80;
                            else
                                getc_euc_cache = d;
                        }
                        else {
                            if (0xA0 < d && d < 0xFF) { /* if GR */
                                c &= 0x7F;  /* convert to MS-kanji */
                                d &= 0x7F;
                                if (!(c & 1)) {
                                    c--;
                                    d += 0x7F - 0x21;
                                }
                                if ((d += 0x40 - 0x21) > 0x7E)
                                    d++;
                                if ((c = (c >> 1) + 0x71) >= 0xA0)
                                    c += 0xE0 - 0xA0;
                            }
                            getc_euc_cache = d;
                        }
                    }
#endif
                }
                vp[p++] = (byte)c;
                cnt++;
            }
            return cnt;
        }
        
/* ------------------------------------------------------------------------ */
        public void fwrite_crc(byte[] p, int n, Stream output)
        {
            // unsigned int *crcp;
            // void *p;
            // int  n;
            // FILE *fp;

            calccrc(p, (uint)n);
            if (output == null || lha.verifyMode)
            {
                return;
            }

            output.Write(p, 0, n);
            
            // if (text_mode) {
            //         if (fwrite_txt(p, n, fp))
            //             fatal_error("File write error");
            //     }
            //     else {
            //         if (fwrite(p, 1, n, fp) < n)
            //             fatal_error("File write error");
            //     }
            // }
        }        
        
        public uint calccrc(byte[] buf, uint n)
        {
            // unsigned int crc;
            // char  *p;
            // unsigned int    n;
            // while (n-- > 0)
            //     crc = UPDATE_CRC(crc, *p++);
            // return crc;
            for (var i = 0; i < n; i++)
            {
                UPDATE_CRC(buf[i]);
            }
            return crc;
        }

    }
}