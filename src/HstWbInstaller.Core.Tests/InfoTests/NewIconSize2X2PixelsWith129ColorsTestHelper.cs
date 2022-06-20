namespace HstWbInstaller.Core.Tests.InfoTests
{
    using System;
    using System.Collections.Generic;
    using System.Linq;
    using System.Text;
    using IO.Info;

    public static class NewIconSize2X2PixelsWith129ColorsTestHelper
    {
        public const int Width = 4;
        public const int Height = 4;
        public const int Depth = 8;
        public const bool Transparent = true;
        public const int ImageNumber = 1;

        public static NewIcon NewIcon = new()
        {
            Width = Width,
            Height = Height,
            Depth = Depth,
            ImagePixels = new byte[]
            {
                255, 254, 253, 252,
                251, 250, 249, 248,
                247, 246, 245, 244,
                243, 242, 241, 240
            },
            // Palette = new[]
            // {
            //     new byte[] { 255, 0, 0 } // red
            // },
            Palette = Enumerable.Range(1, 255).Select(_ => new byte[] { 255, 0, 0 }).ToArray(),
            Transparent = Transparent
        };
        
        public static IEnumerable<TextData> CreateTextDatas()
        {
            return new[] { CreateNewIconHeaderAndPaletteTextData(), CreateNewIconPixelDataTextData() };
        }

        public static TextData CreateNewIconHeaderAndPaletteTextData()
        {
            var textData = new List<byte>(Encoding.ASCII.GetBytes($"IM{ImageNumber}="));
            
            // encode transparent, width and height
            textData.Add((byte)(Transparent ? 66 : 67));
            textData.Add((byte)(0x21 + Width));
            textData.Add((byte)(0x21 + Height));

            // encode number of color / palette entries
            var colors = 1;
            textData.Add((byte)(0x21 + (colors >> 6)));
            textData.Add((byte)(0x21 + (colors & 0x3f)));
            
            
            // new icon uses 8 bits per palette component
            // with only 7 bits available per byte due to the ascii encoding used
            // each palette component bits is therefore split over next byte
            
            // 7 bits left
            
            // first 7 bits of 1st value 255 is added to 1st byte:
            // 87654321
            // --------
            // 01111111 = 127 raw, 208 ascii encoded (0x51 + 127)
            // 7 bits left - 8 = -1 bit left
            // with no bits left, this value is added to text data
            textData.Add(208);
            // -1 bit left + 7 = 6 bit left

            // remaining 1 bit of the value 255 is set to 2nd byte:
            // 87654321
            // --------
            // 01000000
            // = 64 raw
            // 6 bits left
            
            // first 6 bits of 2nd value 0 is added to 2nd byte:
            // 87654321   87654321   87654321
            // --------   --------   --------
            // 01000000 | 00000000 = 01000000 = 64 raw, 96 ascii encoded (0x20 + 64)
            // 6 bits left - 8 = -2 bit left
            // with no bits left, this value is added to text data
            textData.Add(96);
            // -2 bit left + 7 = 5 bit left

            // remaining 2 bits of the 2nd value 0 is set to 3rd byte:
            // 87654321
            // --------
            // 00000000
            // = 0 raw
            // 5 bits left
            
            // first 5 bits of 3nd value 0 is added to 3rd byte:
            // 87654321   87654321   87654321
            // --------   --------   --------
            // 00000000 | 00000000 = 01000000 = 0 raw, 32 ascii encoded (0x20 + 0)
            // 5 bits left - 8 = -3 bit left
            // with no bits left, this value is added to text data
            textData.Add(32);
            // -3 bit left + 7 = 4 bit left
            
            // remaining 3 bits of the 3rd value 0 is set to 4th byte:
            // 87654321
            // --------
            // 00000000
            // = 0 raw
            // 4 bits left

            // = 0 raw, 32 ascii encoded (0x20 + 0)
            // no palette bytes left, encode and add value to new icon bytes
            textData.Add(32);
            
            // terminate text data line
            textData.Add(0);

            return new TextData
            {
                Data = textData.ToArray(),
                Size = (uint)textData.Count
            };
        }
        
        public static TextData CreateNewIconPixelDataTextData()
        {
            var paletteColors = 129;
            var depth = (int)Math.Ceiling(Math.Log(paletteColors) / Math.Log(2)); // depth = 8
            var textData = new List<byte>(Encoding.ASCII.GetBytes($"IM{ImageNumber}="));

            /*
Each byte encodes 7bit (except the RLE bytes)
Bytes 0x20 to 0x6F represent 7bit value 0x00 to 0x4F
Bytes 0xA1 to 0xD0 represent 7bit value 0x50 to 0x7F
Bytes 0xD1 to 0xFF are RLE bytes:
  0xD1 represents  1*7 zero bits,
  0xD2 represents  2*7 zero bits and the last value
  0xFF represents 47*7 zero bits.
               */
            textData.Add(208);
            textData.Add(96);
            textData.Add(32);
            textData.Add(32);
            textData.Add(0);
            
            return new TextData
            {
                Data = textData.ToArray(),
                Size = (uint)textData.Count
            };
            
            // 87654321
            // --------
            // 01111111 = 127

            // 87654321
            // --------
            // 00000020 = 127
            
            
            // bits per pixel data = depth = 8 bits
            
            // pixel data values: 129, 1, 1, 129
            // 7 bits left
            
            // 1st value 129 bits:
            // 87654321
            // --------
            // 10000001
            
            // first 7 bits of 1st value 129 is added to 1st byte:
            // 87654321
            // --------
            // 01000000 = 64 raw, 96 ascii encoded (0x20 + 64)
            // 7 bits left - 8 = -1 bit left
            // with no bits left, the ascii encoded value is added to text data
            textData.Add(96);
            // -1 bit left + 7 = 6 bit left
            
            // remaining 1 bit of the value 129 is set to 2nd byte:
            // 87654321
            // --------
            // 01000000 = 64 raw
            // 6 bits left

            // -----------------------------------------------------------------------
            
            // 2nd value 1 bits:
            // 87654321
            // --------
            // 00000001
            
            // first 6 bits of 2nd value 1 is added to 2nd byte:
            // 87654321   87654321   87654321
            // --------   --------   --------
            // 01000000 | 00000000 = 01000000 = 64 raw, 96 ascii encoded (0x20 + 64)
            // 6 bits left - 8 = -2 bit left
            // with no bits left, the ascii encoded value is added to text data
            textData.Add(96);
            // -2 bit left + 7 = 5 bit left
            
            // remaining 2 bits of the 2nd value 1 is set to 3rd byte:
            // 87654321
            // --------
            // 00100000 = 32 raw
            // 5 bits left

            // -----------------------------------------------------------------------
            
            // 3rd value 1 bits:
            // 87654321
            // --------
            // 00000001
            
            // first 5 bits of 3rd value 1 is added to 3rd byte:
            // 87654321   87654321   87654321
            // --------   --------   --------
            // 00100000 | 00000000 = 01000000 = 32 raw, 64 ascii encoded (0x20 + 32)
            // 5 bits left - 8 = -3 bit left
            // with no bits left, the ascii encoded value is added to text data
            textData.Add(64);
            // -3 bit left + 7 = 4 bit left
            
            // remaining 3 bits of the 3rd value 1 is set to 4th byte:
            // 87654321
            // --------
            // 00010000 = 16 raw
            // 4 bits left

            // -----------------------------------------------------------------------
            
            // 4th value 129 bits:
            // 87654321
            // --------
            // 10000001 = 129 raw
            
            // first 4 bits of 4th value 129 is added to 4th byte:
            // 87654321   87654321   87654321
            // --------   --------   --------
            // 00010000 | 00001000 = 00011000 = 24 raw, 56 ascii encoded (0x20 + 24)
            // 4 bits left - 8 bits used = -4 bit left
            // with no bits left, the ascii encoded value is added to text data
            textData.Add(56);
            // -4 bit left + 7 bits available = 3 bit left
            
            // remaining 4 bits of the 4th value 129 is set to 5th byte:
            // 87654321
            // --------
            // 00001000 = 8 raw
            // 3 bits left
            
            // = 8 raw, 40 ascii encoded (0x20 + 8)
            // no palette bytes left, encode and add value to new icon bytes
            textData.Add(40);

            // terminate text data line
            textData.Add(0);

            return new TextData
            {
                Data = textData.ToArray(),
                Size = (uint)textData.Count
            };
        }
    }
}