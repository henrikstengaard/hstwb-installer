namespace HstWbInstaller.Core.IO.Info
{
    using System.Collections.Generic;
    using System.Linq;
    using System.Text;

    /// <summary>
    /// iconverter ported new icon ascii encoder. currently limited to 128 colors due to encoding issues
    /// </summary>
    public class IConverterNewIconAsciiEncoder
    {
        private readonly int imageNumber;

        private readonly NewIcon newIcon;
        
        private readonly List<TextData> toolTypes;
        private readonly List<byte> currentLine;
        private int BytesLeft => Constants.NewIcon.MAX_STRING_LENGTH - currentLine.Count - (bitsleft < 7 ? 1 : 0);
        private int bitsleft;
        private byte currentValue;

        public IConverterNewIconAsciiEncoder(int imageNumber, NewIcon newIcon)
        {
            // if (width > 93)
            // {
            //     throw new ArgumentOutOfRangeException(nameof(width), "Max image width is 93");
            // }
            //
            // if (height > 93)
            // {
            //     throw new ArgumentOutOfRangeException(nameof(width), "Max image height is 93");
            // }
            
            this.imageNumber = imageNumber;
            this.newIcon = newIcon;
            toolTypes = new List<TextData>();
            currentLine = new List<byte>(LineHeader(imageNumber))
            {
                // header
                (byte)(newIcon.Transparent ? 66 : 67),
                (byte)(0x21 + newIcon.Width),
                (byte)(0x21 + newIcon.Height)
            };

            bitsleft = 7;
            currentValue = 0;
        }

        public IEnumerable<TextData> Encode()
        {
            EncodePalette(newIcon.Palette);
            EncodeImage(newIcon.ImagePixels);
            return toolTypes.ToList();
        }

        private void EncodePalette(byte[][] palette)
        {
            // palette entries
            currentLine.Add((byte)(0x21 + (palette.Length >> 6)));
            currentLine.Add((byte)(0x21 + (palette.Length & 0x3f)));

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

        private void EncodeImage(byte[] imagePixels)
        {
            var offset = 0;
            for (var y = 0; y < newIcon.Height; y++)
            {
                for (var x = 0; x < newIcon.Width; x++)
                {
                    EncodePixel(imagePixels[offset++]);
                }
            }
            
            Flush();
        }

        public void Add(byte value)
        {
            currentLine.Add(value);
        }

        private void EncodeColorComponent(byte value)
        {
            if (BytesLeft <= 0)
            {
                Flush();
            }
            
            currentValue |= (byte)(value >> (8 - bitsleft));
                    
            EncodeBits(ref currentValue, BytesLeft);
            currentLine.Add(currentValue);
            
            bitsleft -= 1;
            currentValue = (byte)((value << bitsleft) & 0x7f);
            if (bitsleft == 0)
            {
                currentValue = (byte)(value & 0x7f);
                EncodeBits(ref currentValue, BytesLeft);
                currentLine.Add(currentValue);
                currentValue = 0;
                
                if (BytesLeft <= 0)
                {
                    Flush();
                }
                
                bitsleft = 7;
            }
        }

        private void EncodePixel(byte value)
        {
            if (bitsleft < newIcon.Depth)
            {
                currentValue |= (byte)(value >> (newIcon.Depth - bitsleft));
                bitsleft += 7;
                
                EncodeBits(ref currentValue, BytesLeft);
                currentLine.Add(currentValue);
                
                currentValue = 0;
            }

            bitsleft -= newIcon.Depth;
            currentValue |= (byte)((value << bitsleft) & 0x7f);

            if (BytesLeft == 0 && bitsleft < newIcon.Depth)
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

        private void Flush()
        {
            if (bitsleft < 7)
            {
                EncodeBits(ref currentValue, BytesLeft);
                currentLine.Add(currentValue);
            }

            Next();
        }

        private void Next()
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