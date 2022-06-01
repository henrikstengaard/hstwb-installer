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
            newIcon.ImagePixels = new byte[newIcon.Width][];
            for (var x = 0; x < newIcon.Width; x++)
            {
                newIcon.ImagePixels[x] = new byte[newIcon.Height];
            }

            // get image pixels from decoded data
            offset = bitmap_start_pos;
            for (var y = 0; y < newIcon.Height; y++)
            {
                for (var x = 0; x < newIcon.Width; x++)
                {
                    newIcon.ImagePixels[x][y] = decoded[offset++];
                }
            }

            return newIcon;
        }

        // public NewIcon Decode()
        // {
        //     if (newIcon != null)
        //     {
        //         return newIcon;
        //     }
        //     
        //     
        //     
        //     
        //     
        //     
        //
        //     newIcon = new NewIcon
        //     {
        //         Transparent = img[0] == 66,
        //         Width = img[1] - 0x21,
        //         Height = img[2] - 0x21
        //     };
        //     var paletteEntries = ((img[3] - 0x21) << 6) + (img[4] - 0x21);
        //     newIcon.Depth = (int)Math.Ceiling(Math.Log(paletteEntries) / Math.Log(2));
        //     
        //     
        //     var depth = 0;
        //     var rest = paletteEntries-1;
        //     while ( rest > 0 ) {
        //         rest = rest >> 1;
        //         depth++;
        //     }
        //     if ( depth == 0 ) depth = 1;	/*** If ncolors was 1 */
        //     if ( depth > 8 ) {
        //         depth = 8;	/*** If ncolors was greater than 256 */
        //         paletteEntries = 256;
        //     }
        //     
        //     dataindex += 5;
        //
        //     InitData7();
        //     
        //     var palette = new List<byte[]>();
        //     for (var p = 0; p < paletteEntries; p++)
        //     {
        //         var r = ReadBits7(8);
        //         var g = ReadBits7(8);
        //         var b = ReadBits7(8);
        //         var color = new byte[3];
        //         palette24(color, r, g, b);
        //         palette.Add(color);
        //     }
        //     
        //     while (img[dataindex] != 0 && img[dataindex + 1] != 0 && img[dataindex + 2] != 0)
        //     {
        //         var r = ReadBits7(8);
        //         var g = ReadBits7(8);
        //         var b = ReadBits7(8);
        //         var color = new byte[3];
        //         palette24(color, r, g, b);
        //         palette.Add(color);
        //     }
        //
        //     newIcon.Palette = palette.ToArray();
        //
        //     while (img[dataindex] != 0)
        //     {
        //         dataindex++;
        //     } 
        //     dataindex++;
        //     
        //     newIcon.ImagePixels = new byte[newIcon.Width][];
        //     for (var x = 0; x < newIcon.Width; x++)
        //     {
        //         newIcon.ImagePixels[x] = new byte[newIcon.Height];
        //     }
        //
        //     // read the image
        //     InitData7();
        //     // for (var y = 0; y < newIcon.Height; y++)
        //     // {
        //     //     newIcon.ImagePixels[y] = new byte[newIcon.Width];
        //     //     for (var x = 0; x < newIcon.Width; x++)
        //     //     {
        //     //         newIcon.ImagePixels[y][x] = ReadBits7(newIcon.Depth);
        //     //         // newIcon.ImagePixels[x][y] = ReadBits7(newIcon.Depth);
        //     //     }
        //     // }
        //     for (var y = 0; y < newIcon.Height; y++)
        //     {
        //         for (var x = 0; x < newIcon.Width; x++)
        //         {
        //             newIcon.ImagePixels[x][y] = ReadBits7(newIcon.Depth);
        //             // newIcon.ImagePixels[x][y] = ReadBits7(newIcon.Depth);
        //         }
        //     }
        //     
        //     return newIcon;
        // }

//         private void InitData7()
//         {
//             datastart = dataindex;
//             bitsleft = 7;
//             datanleft = 0;
//         }
//         
//         private byte ReadBits7(int depth)
//         {
//             //unsigned char c;
//             int bits;
//
//             if (bitsleft == 0)
//             {
//                 bitsleft = 7;
//                 DataAdvance7();
//             }
//
//             if (bitsleft >= depth)
//             {
//                 bitsleft -= depth;
//                 bits = (ReadChar7() >> bitsleft) & ((1 << depth) - 1);
//             }
//             else
//             {
//                 bits = (ReadChar7() << (depth - bitsleft)) & ((1 << depth) - 1);
//                 bitsleft = bitsleft + 7 - depth;
//                 if (DataAdvance7())
//                 {
//                     bitsleft -= depth;
//                     bits = (ReadChar7() >> bitsleft) & ((1 << depth) - 1);
//                 }
//                 bits |= (ReadChar7() >> bitsleft) & ((1 << depth) - 1);
//             }
//
//             var t = (byte)bits;
//
//             if (t != bits)
//             {
//                 
//             }
//             
//             return (byte)bits;
//         }
//
//         private byte ReadChar7()
//         {
//             if (datanleft > 0)
//             {
// // printf("datanleft: %d ", datanleft);
//                 return 0;
//             }
//
//             if (dataindex >= img.Length)
//             {
//                 return 0;
//             }
//
//             if (img[dataindex] < 0x80)
//             {
//                 return (byte)(img[dataindex] - 0x20);
//             }
//             if (img[dataindex] <= 0xd0)
//             {
//                 return (byte)(img[dataindex] - 0xa1 + 0x50);
//             }
//             datanleft = img[dataindex] - 0xd0;
//             return 0;
//         }
//         
//         private int FinishData7()
//         {
//             dataindex++;
//             return dataindex - datastart;
//         }
//
//         private bool DataAdvance7()
//         {
//             // advance to the next data character
//             // unless we have RLE zero bytes to process
//             if (datanleft > 1)
//             {
//                 datanleft--;
//                 return false;
//             }
//             datanleft = 0;
//
//             dataindex++;
//
//             if (dataindex >= img.Length)
//             {
//                 return false;
//             }
//             
//             if (img[dataindex] == 0)
//             {
//                 // skip to the next tooltype (no error checking... sorry)
//                 //dataindex += 9;
//                 dataindex++;
//                 bitsleft = 7;
//                 // indicate buffered bits need to be flushed
//                 return true;
//             }
//             return false;
//         }

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