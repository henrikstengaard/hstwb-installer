namespace HstWbInstaller.Core.Tests.InfoTests
{
    using System;
    using System.Collections.Generic;
    using System.Text;
    using IO.Info;

    public static class NewIconSized2X2PixelsWith2ColorsTestHelper
    {
        public const int Width = 2;
        public const int Height = 2;
        public const int Depth = 1;
        public const bool Transparent = true;
        public const int ImageNumber = 1;

        public static NewIcon NewIcon = new()
        {
            Width = Width,
            Height = Height,
            Depth = Depth,
            ImagePixels = new byte[]
            {
                0, 1,
                1, 0
            },
            Palette = new[]
            {
                new byte[] { 255, 0, 0 }, // red
                new byte[] { 0, 255, 0 } // green
            },
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
            var colors = Convert.ToInt32(Math.Pow(2, Depth));
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
            
            // first 4 bits of 4th value 0 is added to 4th byte:
            // 87654321   87654321   87654321
            // --------   --------   --------
            // 00000000 | 00000000 = 01000000 = 0 raw, 32 ascii encoded (0x20 + 0)
            // 4 bits left - 8 bits used = -4 bit left
            // with no bits left, this value is added to text data
            textData.Add(32);
            // -4 bit left + 7 bits available = 3 bit left
            
            // remaining 4 bits of the 4th value 0 is set to 5th byte:
            // 87654321
            // --------
            // 00000000
            // = 0 raw
            // 3 bits left
            
            // first 3 bits of 5th value 255 is added to 5th byte:
            // 87654321   87654321   87654321
            // --------   --------   --------
            // 00000000 | 00000111 = 00000111 = 7 raw, 39 ascii encoded (0x20 + 7)
            // 3 bits left - 8 bits used = -5 bit left
            // with no bits left, this value is added to text data
            textData.Add(39);
            // -5 bit left + 7 bits available = 2 bit left
            
            // remaining 5 bits of the 5th value 255 is set to 6th byte:
            // 87654321
            // --------
            // 01111100
            // = 124 raw
            // 2 bits left
            
            // first 2 bits of 6th value 0 is added to 6th byte:
            // 87654321   87654321   87654321
            // --------   --------   --------
            // 01111100 | 00000000 = 01111100 = 124 raw, 205 ascii encoded (0x51 + 124)
            // 2 bits left - 8 bits used = -6 bit left
            // with no bits left, this value is added to text data
            textData.Add(205);
            // -6 bit left + 7 bits available = 1 bit left

            // remaining 6 bits of the 6th value 0 is set to 7th byte:
            // 87654321
            // --------
            // 00000000
            // = 0 raw
            // 1 bits left
            
            // = 0 raw, 32 ascii encoded (0x20 + 0)
            // no palette bytes left, encode and add value to new icon bytes
            textData.Add(32);
            
            // overview of palette bytes, bits, raw and encoded values
            // palette:      255       0          0        0          255       0
            //            |------  ||-----  -||----  --||---  ---||--  ----||- -----|
            //           87654321 87654321 87654321 87654321 87654321 87654321 87654321  
            //           -------- -------- -------- -------- -------- -------- -------- 
            // bits:     01111111 01000000 00000000 00000000 00000111 01111100 00000000
            // raw:        127       64       0        0        7       124       0  
            // encoded:    208       96       32       32       39      205       32
            
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
            var textData = new List<byte>(Encoding.ASCII.GetBytes($"IM{ImageNumber}="));

            // bits per pixel data = depth = 1 bit
            
            // pixel data values: 0, 1, 1, 0
            // 7 bits left
            
            // the 1 bit of 1st value 0 is added to 1st byte:
            // 87654321
            // --------
            // 00000000 = 0 raw, 32 ascii encoded (0x20 + 0)
            // 7 bits left - 1 = 6 bits left
            
            // the 1 bit of 2nd value 1 is added to 1st byte:
            // 87654321   87654321   87654321
            // --------   -------- = -------- 
            // 00000000 | 00100000 = 00100000 = 32 raw, 64 ascii encoded (0x20 + 32)
            // 6 bits left - 1 = 5 bits left
            
            // the 1 bit of 3rd value 1 is added to 1st byte:
            // 87654321   87654321   87654321
            // --------   -------- = -------- 
            // 00100000 | 00010000 = 00110000 = 48 raw, 80 ascii encoded (0x20 + 48)
            // 5 bits left - 1 = 4 bits left
            
            // the 1 bit of 4th value 0 is added to 1st byte:
            // 87654321   87654321   87654321
            // --------   -------- = -------- 
            // 00110000 | 00000000 = 00110000 = 48 raw, 80 ascii encoded (0x20 + 48)
            // 4 bits left - 1 = 3 bit left

            // with no pixel data left, this value is added to text data
            textData.Add(80);
            
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