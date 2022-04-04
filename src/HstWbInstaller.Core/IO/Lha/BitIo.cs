namespace HstWbInstaller.Core.IO.Lha
{
    using System.IO;

    public class BitIo
    {
        // https://github.com/jca02266/lha/blob/03475355bc6311f7f816ea9a88fb34a0029d975b/src/bitio.c
        
        public readonly Stream stream;

        // https://github.com/jca02266/lha/blob/03475355bc6311f7f816ea9a88fb34a0029d975b/src/lha.h#L380
        public ushort bitbuf;
        public const byte SIZE_BITBUF = 2; // sizeof(ushort)

        public byte subbitbuf, bitcount;

        
        public bool unpackable;
        // https://github.com/jca02266/lha/blob/master/src/lha.h#L362
        public int origsize;
        public int compsize; 
        
        public BitIo(Stream stream, int origsize, int compsize)
        {
            this.stream = stream;
            this.origsize = origsize;
            this.compsize = compsize;
            this.bitbuf = 0;
            this.subbitbuf = 0;
            this.bitcount = 0;
        }

        public void FillBuf(int n)
        {
            while (n > bitcount)
            {
                n -= bitcount;
                bitbuf = (ushort)((bitbuf << bitcount) + (subbitbuf >> (Constants.CHAR_BIT - bitcount)));
                if (compsize != 0)
                {
                    compsize--;
                    var c = stream.ReadByte();
                    if (c == -1)
                    {
                        throw new IOException("cannot read stream");
                    }

                    subbitbuf = (byte)c;
                }
                else
                    subbitbuf = 0;

                bitcount = Constants.CHAR_BIT;
            }

            bitcount -= (byte)n;
            bitbuf = (ushort)((bitbuf << n) + (subbitbuf >> (Constants.CHAR_BIT - n)));
            subbitbuf <<= n;
        }

        public int GetBits(int n)
        {
            var x = bitbuf >> (2 * Constants.CHAR_BIT - n);
            FillBuf(n);
            return x;
        }
        
        public void PutCode(byte n, ushort x)
        {
            /* Write leftmost n bits of x */
            while (n >= bitcount) {
                n -= bitcount;
                subbitbuf += (byte)(x >> (Constants.USHRT_BIT - bitcount));
                x <<= bitcount;
                if (compsize < origsize) {
                    // if (fwrite(&subbitbuf, 1, 1, outfile) == 0) {
                    //     fatal_error("Write error in bitio.c(putcode)");
                    // }
                    stream.WriteByte(subbitbuf);
                    compsize++;
                }
                else
                    unpackable = true;
                subbitbuf = 0;
                bitcount = Constants.CHAR_BIT;
            }
            subbitbuf += (byte)(x >> (Constants.USHRT_BIT - bitcount));
            bitcount -= n;
        }        
        
        public void PutBits(byte n, ushort x)
        {
            /* Write rightmost n bits of x */
            x <<= Constants.USHRT_BIT - n;
            PutCode(n, x);
        }        
        
        public void InitGetBits()
        {
            bitbuf = 0;
            subbitbuf = 0;
            bitcount = 0;
            FillBuf(2 * Constants.CHAR_BIT);
        }

        public void InitPutBits()
        {
            bitcount = Constants.CHAR_BIT;
            subbitbuf = 0;
        }        
        
        public int PeekBits(int n)
        {
            return bitbuf >> (SIZE_BITBUF * 8 - n);
        }
    }
}