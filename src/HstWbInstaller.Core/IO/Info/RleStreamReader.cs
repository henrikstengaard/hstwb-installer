namespace HstWbInstaller.Core.IO.Info
{
    using System;
    using System.IO;

    public sealed class RleStreamReader : IDisposable
    {
        private readonly Stream stream;

        private bool disposed;

        private int dataindex;
        private int datadepth;
        private readonly int maxLength;
        private int count;
        private int bitsleft;
        private int datanleft;
        private int dataleft;

        public RleStreamReader(Stream stream, int depth, int maxLength = 0)
        {
            this.stream = stream;
            dataindex = stream.ReadByte();
            datadepth = depth;
            this.count = 0;
            this.maxLength = maxLength;
            bitsleft = 8;
            datanleft = 0;
            dataleft = 0;
        }

        public byte ReadData8()
        {
            byte c = 0;

            if (datanleft > 0)
            {
                datanleft--;
                if (dataleft < 0)
                {
                    return ReadBits8(datadepth);
                }

                return (byte)dataleft;
            }

            var rle = ReadBits8(8);
            if (rle < 128)
            {
                c = ReadBits8(datadepth);
                datanleft = rle;
                dataleft = -1;
            }
            else if (rle > 128)
            {
                c = ReadBits8(datadepth);
                dataleft = c;
                datanleft = 257 - rle - 1;
            }

            return c;
        }

        public byte ReadBits8(int depth)
        {
            int bits;

            if (bitsleft == 0)
            {
                bitsleft = 8;
                dataindex = ReadNext();
            }

            if (bitsleft == 8 && depth == 8)
            {
                bitsleft = 0;
                return (byte)dataindex;
            }

            if (bitsleft >= depth)
            {
                bitsleft -= depth;
                bits = (dataindex >> bitsleft) & ((1 << depth) - 1);
            }
            else
            {
                bits = (dataindex << (depth - bitsleft)) & ((1 << depth) - 1);
                bitsleft = bitsleft + 8 - depth;
                dataindex = ReadNext();
                bits |= ((dataindex >> bitsleft) & ((1 << depth) - 1));
            }

            return (byte)bits;
        }

        private int ReadNext()
        {
            if (maxLength > 0 && count > maxLength)
            {
                throw new IOException($"Reached max length {maxLength}");
            }
            
            var value = stream.ReadByte();
            count++;
            
            return value;
        }

        // private int finishdata8()
        // {
        //   dataindex++;
        //   return dataindex - datastart;
        // }

        private void Dispose(bool disposing)
        {
            if (disposed)
            {
                return;
            }

            if (disposing)
            {
                // dispose
            }

            disposed = true;
        }

        public void Dispose() => Dispose(true);

        /*
  void initdata8(unsigned char * start, int depth)
  {
    datastart = start;
    dataindex = start;
    datadepth = depth;
    bitsleft = 8;
    datanleft = 0;
    dataleft = 0;
  }
  
  unsigned char readdata8()
  {
    unsigned char c;
    int rle;
  
    if (datanleft > 0)
      {
        datanleft--;
        if (dataleft < 0)
          return readbits8(datadepth);
        else
          return dataleft;
      }
  
    rle = readbits8(8);
    if (rle < 128)
      {
        c = readbits8(datadepth);
        datanleft = rle;
        dataleft = -1;
      }
    else if (rle > 128)
      {
        c = readbits8(datadepth);
        dataleft = c;
        datanleft = 257 - rle - 1;
      }
    return c;
  }
  
  unsigned char readbits8(int depth)
  {
    unsigned char c;
    int bits;
  
    if (bitsleft == 0)
      {
        bitsleft = 8;
        dataindex++;
      }
  
      if (bitsleft == 8 && depth == 8)
        {
          bitsleft = 0;
          return *dataindex;
        }
  
      if (bitsleft >= depth)
        {
          bitsleft -= depth;
          bits = (*dataindex >> bitsleft) & ((1 << depth) - 1);
        }
      else
        {
          bits = (*dataindex << (depth - bitsleft)) & ((1 << depth) - 1);
          bitsleft = bitsleft + 8 - depth;
          dataindex++;
          bits = bits | ((*dataindex >> bitsleft) & ((1 << depth) - 1));
        }
  
    return bits;
  }
  
  int finishdata8()
  {
    dataindex++;
    return dataindex - datastart;
  }
  
   */
    }
}