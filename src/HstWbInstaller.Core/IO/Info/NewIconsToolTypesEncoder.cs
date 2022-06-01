namespace HstWbInstaller.Core.IO.Info
{
    using System;
    using System.Collections.Generic;
    using System.Text;

    public class NewIconsToolTypesEncoder
    {
        private readonly int imageNumber;
        private readonly int width;
        private readonly int height;
        private readonly int depth;
        public const int MAX_STRING_LENGTH = 127;

        private List<TextData> toolTypes;
        private List<byte> currentLine;
        private int bytesleft => MAX_STRING_LENGTH - currentLine.Count;
        private int bitsleft;
        private byte currentValue;

        public NewIconsToolTypesEncoder(int imageNumber, int width, int height, int depth, bool transparent)
        {
            if (width > 93)
            {
                throw new ArgumentOutOfRangeException(nameof(width), "Max image width is 93");
            }

            if (height > 93)
            {
                throw new ArgumentOutOfRangeException(nameof(width), "Max image height is 93");
            }
            
            this.imageNumber = imageNumber;
            this.width = width;
            this.height = height;
            this.depth = depth;
            toolTypes = new List<TextData>();
            currentLine = new List<byte>(LineHeader(imageNumber));
            
            // header
            currentLine.Add((byte)(transparent ? 66 : 67));
            currentLine.Add((byte)(0x21 + width));
            currentLine.Add((byte)(0x21 + height));
            
            bitsleft = 7;
            currentValue = 0;
        }

        public void EncodePalette(byte[][] palette)
        {
            // palette entries
            currentLine.Add(0x21);
            currentLine.Add((byte)(0x21 + palette.Length));

            // encode palette
            for (var p = 0; p < palette.Length; p++)
            {
                for (var c = 0; c < 3; c++)
                {
                    EncodeColorComponent(palette[p][c]);
                }
            }
            
            Flush();
        }

        public void EncodeImage(byte[][] imagePixels)
        {
            for (var y = 0; y < height; y++)
            {
                for (var x = 0; x < width; x++)
                {
                    EncodePixel(imagePixels[y][x]);
                }
            }
            
            Flush();
        }

        public IEnumerable<TextData> GetToolTypes()
        {
            return toolTypes;
        }

        public void Add(byte value)
        {
            currentLine.Add(value);
        }

        public void EncodeColorComponent(byte value)
        {
            currentValue |= (byte)(value >> (8 - bitsleft));
                    
            EncodeBits(ref currentValue, bytesleft);
            currentLine.Add(currentValue);
            
            if (bytesleft <= 0)
            {
                Next();
            }
            
            bitsleft -= 1;
            currentValue = (byte)((value << bitsleft) & 0x7f);
            if (bitsleft == 0)
            {
                currentValue = (byte)(value & 0x7f);
                EncodeBits(ref currentValue, bytesleft);
                currentLine.Add(currentValue);
                currentValue = 0;
                
                if (bytesleft <= 0)
                {
                    Next();
                }
                
                bitsleft = 7;
            }
        }

        public void EncodePixel(byte value)
        {
            if (bitsleft < depth)
            {
                currentValue |= (byte)(value >> (depth - bitsleft));
                bitsleft += 7;
                
                EncodeBits(ref currentValue, bytesleft);
                currentLine.Add(currentValue);
                
                currentValue = 0;
            }

            bitsleft -= depth;
            currentValue |= (byte)((value << bitsleft) & 0x7f);

            if (bytesleft == 0 && bitsleft < depth)
            {
                Flush();
                //var stringlen = 128 - bytesleft;
                // e = encodebits(img, bytesleft);
                // EncodeBits(ref currentValue, bytesleft);
                // img += e;
                // *(img++) = 0;
                // nttypes++;
                // bitsleft = 0;
            }
        }
        
        public void Flush()
        {
            if (bitsleft < 7)
            {
                EncodeBits(ref currentValue, bytesleft);
                currentLine.Add(currentValue);
            }

            Next();
        }

        public void Next()
        {
            // add tool types line termination
            currentLine.Add(0);
            
            toolTypes.Add(new TextData
            {
                Size = (uint)currentLine.Count,
                Data = currentLine.ToArray()
            });
            
            currentLine.Clear();
            currentLine.AddRange(LineHeader(imageNumber));
            currentValue = 0;
            bitsleft = 7;
        }
        

        private static byte EncodeBits(ref byte img, int bytesLeft)
        {
            // unsigned char c;

            var c = img;

/*
  // compress repeated zeros, doesn't work, needs to be fixed
  if (c == 0 && bytesleft < 122)
    {
      if (*(img - 1) == 0x20)
        {
          *(img - 1) = 0xd2;
          return 0;
        }
      else if (*(img - 1) > 0xd1 && *(img - 1) < 0xff)
        {
          (*(img - 1))++;
          return 0;
        }
    }
*/

            if (c < 0x50)
                c = (byte)(c + 0x20);
            else
                c = (byte)(c + 0x51);
            img = c;
            return 1;
        }
        
        private static byte[] LineHeader(int imageNumber)
        {
            return Encoding.ASCII.GetBytes($"IM{imageNumber}=");
        }
    }
}