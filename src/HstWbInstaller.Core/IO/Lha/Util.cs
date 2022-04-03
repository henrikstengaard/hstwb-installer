namespace HstWbInstaller.Core.IO.Lha
{
    using System;
    using System.IO;

    public static class Util
    {
        //private static bool text_mode;
        // https://github.com/jca02266/lha/blob/03475355bc6311f7f816ea9a88fb34a0029d975b/src/util.c

        public static int CopyFile(Stream source, Stream destination, int size, bool text_mode, int text_flg, CrcIo crcIo)
        {
            /* return: size of source file */
            // FILE *f1;
            // FILE *f2;
            // off_t size;
            // int text_flg;               /* 0: binary, 1: read text, 2: write text */
            // unsigned int *crcp;

            ushort xsize;
            // char* buf;
            int rsize = 0;

            if (!text_mode)
                text_flg = 0;

            //buf = (char *)xmalloc(BUFFERSIZE);
            var buf = new byte[Constants.BUFFERSIZE];
            //if (!crc.HasValue)
            //    crc = CrcIo.InitializeCrc();
            if (text_flg != 0)
                crcIo.init_code_cache();
            while (size > 0)
            {
                /* read */
                if (text_flg == 1)
                {
                    xsize = (ushort)crcIo.fread_txt(buf, Constants.BUFFERSIZE, source);
                    if (xsize == 0)
                        break;
                    throw new IOException("file read error");
                }
                else
                {
                    xsize = (ushort)((size > Constants.BUFFERSIZE) ? Constants.BUFFERSIZE : size);
                    if (source.Read(buf, 0, xsize) != xsize)
                    {
                        throw new Exception("file read error");
                    }

                    if (size < xsize)
                        size = 0;
                    else
                        size -= xsize;
                }

                /* write */
                if (destination != null)
                {
                    destination.Write(buf, 0, xsize);
                }

                /* calculate crc */
                crcIo.calccrc(buf, xsize);
                // if (crc != 0)
                // {
                //     crc = calccrc(*crcp, buf, xsize);
                // }

                rsize += xsize;
            }

            return rsize;
        }
    }
}