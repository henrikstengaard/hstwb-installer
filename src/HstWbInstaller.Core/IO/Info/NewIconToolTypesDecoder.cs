namespace HstWbInstaller.Core.IO.Info
{
    using System;
    using System.Collections.Generic;
    using System.Linq;
    using System.Text;

    public class NewIconToolTypesDecoder
    {
        private NewIcon newIcon;

        private readonly IEnumerable<TextData> textDatas;
        private byte[] newIconData;

        // private int datastart;
        // private int dataindex;
        // private int bitsleft;
        // private int datanleft;

        private byte pendingData;
        private int pendingDataBitsUsed;
        private int bitsPerPixel;

        private bool readingPalette;

        /// <summary>
        /// 
        /// </summary>
        /// <param name="textDatas"></param>
        public NewIconToolTypesDecoder(IEnumerable<TextData> textDatas)
        {
            this.textDatas = textDatas;
        }

        private void GetNewIconData(int imageNumber)
        {
            // get image number text data
            var imageToolTypes =
                textDatas.Where(x => x.Size >= 4 && Encoding.ASCII.GetString(x.Data, 0, 4) == $"IM{imageNumber}=")
                    .ToList();
            
            // build new icon data by cutting off "IM?=" and appending to data array
            newIconData = new byte[imageToolTypes.Sum(x => x.Size - 4)];
            var offset = 0;
            foreach (var textData in imageToolTypes)
            {
                var dataLength = (int)(textData.Size - 4);  
                Array.Copy(textData.Data, 4, newIconData, offset, dataLength);
                offset += dataLength;
            }
        }

        private void do_newicons_append_bit(List<byte> f, byte b)
        {
            if (pendingDataBitsUsed == 0)
            {
                pendingData = 0;
            }

            pendingData = (byte)((pendingData << 1) | (b & 0x1));
            pendingDataBitsUsed++;

            if (readingPalette)
            {
                // read palette using 8 bits
                if (pendingDataBitsUsed == 8)
                {
                    f.Add(pendingData);
                    pendingDataBitsUsed = 0;
                }

                return;
            }

            if (pendingDataBitsUsed >= bitsPerPixel)
            {
                f.Add(pendingData);
                pendingDataBitsUsed = 0;
            }
        }

        private static int Log2RoundedUp(int n)
        {
            if (n <= 2) return 1;
            for (var i = 2; i < 32; i++)
            {
                if (n <= (1) << i) return i;
            }

            return 32;
        }

        public NewIcon Decode(int imageNumber)
        {
            GetNewIconData(imageNumber);
// ----
            var decoded = new List<byte>();

            var rle_len = 0;
            byte tmpb = 0;
            var bitmap_start_pos = 0;

            var trns_code = newIconData[0];
            var has_trns = trns_code == 'B';
            var width_code = newIconData[1];
            var height_code = newIconData[2];

            var b0 = newIconData[3];
            var b1 = newIconData[4];
            var ncolors = (((b0) - 0x21) << 6) + ((b1) - 0x21);
            if (ncolors < 1) ncolors = 1;
            if (ncolors > 256) ncolors = 256;

            readingPalette = true;
            pendingData = 0;
            pendingDataBitsUsed = 0;
            bitsPerPixel = Log2RoundedUp(ncolors);

            for (var srcpos = 5; srcpos < newIconData.Length; srcpos++)
            {
                b0 = newIconData[srcpos];
                if ((b0 >= 0x20 && b0 <= 0x6f) || (b0 >= 0xa1 && b0 <= 0xd0))
                {
                    if (b0 <= 0x6f) b1 = (byte)(b0 - 0x20);
                    else b1 = (byte)(0x50 + (b0 - 0xa1));

                    for (var i = 0; i < 7; i++)
                    {
                        tmpb = (byte)((b1 >> (6 - i)) & 0x01);
                        do_newicons_append_bit(decoded, tmpb);
                    }
                }
                else if (b0 >= 0xd1)
                {
                    // RLE compression for "0" bits
                    tmpb = 0;
                    rle_len = 7 * (b0 - 0xd0);
                    for (var i = 0; i < rle_len; i++)
                    {
                        do_newicons_append_bit(decoded, tmpb);
                    }
                }
                else if (b0 == 0x00)
                {
                    // End of a line.
                    // Throw away any bits we've decoded that haven't been used yet.
                    pendingDataBitsUsed = 0;
                }

                if (readingPalette && decoded.Count >= ncolors * 3)
                {
                    readingPalette = false;

                    // skip till after next zero, end of newicon line
                    while (newIconData[srcpos] != 0)
                    {
                        srcpos++;
                    }

                    pendingDataBitsUsed = 0;
                    bitmap_start_pos = decoded.Count;
                }
            }

            newIcon = new NewIcon
            {
                Transparent = has_trns,
                Width = width_code - 0x21,
                Height = height_code - 0x21,
                Depth = (int)Math.Ceiling(Math.Log(ncolors) / Math.Log(2))
            };

            var offset = 0;

            // get palette from decoded data
            var palette = new List<byte[]>();
            for (var p = 0; p < (ncolors == 256 ? ncolors - 1 : ncolors); p++, offset += 3)
            {
                palette.Add(new[]
                {
                    decoded[offset], decoded[offset + 1], decoded[offset + 2], (byte)(p == 0 && has_trns ? 0 : 255)
                });
            }

            newIcon.Palette = palette.ToArray();

            // create image pixels
            newIcon.ImagePixels = new byte[newIcon.Width * newIcon.Height];

            // get image pixels from decoded data
            offset = bitmap_start_pos;
            var imagePixelsOffset = 0;
            for (var y = 0; y < newIcon.Height; y++)
            {
                for (var x = 0; x < newIcon.Width; x++)
                {
                    if (imagePixelsOffset >= newIcon.ImagePixels.Length)
                    {
                        continue;
                    }

                    if (offset >= decoded.Count)
                    {
                        continue;
                    }
                    
                    newIcon.ImagePixels[imagePixelsOffset++] = decoded[offset++];
                }
            }

            return newIcon;
        }
        
        private void palette8(byte[] color, int l)
        {
            // if (l < 10)
            //     snprintf(s, 20, "\033[40m ");
            // else if (l > 245)
            //     snprintf(s, 20, "\033[48;5;%dm ", 16 + 36 * 5 + 6 * 5 + 5);
            // else
            //     snprintf(s, 20, "\033[48;5;%dm ", 231 + l * 26 / 256);
            color[0] = (byte)l;
            color[1] = (byte)l;
            color[2] = (byte)l;
        }

        private void palette24(byte[] color, int r, int g, int b)
        {
            if (r == g && g == b)
                palette8(color, g);
            else
            {
                color[0] = (byte)r;
                color[1] = (byte)g;
                color[2] = (byte)b;
            }
        }
    }
}