namespace HstWbInstaller.Core.IO.Info
{
    using System.Collections.Generic;
    using System.Linq;
    using System.Text;

    public static class NewIconWriter
    {
        public static byte encodebits(ref byte img, int bytesLeft)
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

        // unsigned char pal[4][256][3];
        // img = imgencode(1, img, (unsigned char *)pal[palguess], p1);
        // unsigned char pal[4][256][3];
        public static void imgencode(int num, byte[][] p, int imgwidth, int imgheight, int imgdepth, byte[][] pixel)
        {
            // int x, y, e, px, bytesleft = 0, bitsleft = 0;
            // unsigned char *stringlen;
            //
            // if (debug)
            //   puts("imgencode");

            var toolTypes = new List<byte[]>();

            if (num == 1)
            {
                toolTypes.Add(Encoding.ASCII.GetBytes(" ").Concat(new byte[] { 0 }).ToArray());
                toolTypes.Add(Encoding.ASCII.GetBytes("*** DON'T EDIT THE FOLLOWING LINES!! ***")
                    .Concat(new byte[] { 0 }).ToArray());
            }

            // if (num == 1)
            //   {
            //     *(img++) = 0;
            //     *(img++) = 0;
            //     *(img++) = 0;
            //     *(img++) = 2;
            //     *(img++) = ' ';
            //     *(img++) = 0;
            //     nttypes++;
            //
            //     *(img++) = 0;
            //     *(img++) = 0;
            //     *(img++) = 0;
            //     *(img++) = 41;
            //     strncpy((char *)img, "*** DON'T EDIT THE FOLLOWING LINES!! ***", 100);
            //     img = img + 40;
            //     *(img++) = 0;
            //     nttypes++;
            //   }


            var transp = 'C';
            var backfill = false;

            // *(img++) = 0;
            // *(img++) = 0;
            // *(img++) = 0;
            // stringlen = img;
            // *(img++) = 24;
            // *(img++) = 'I';
            // *(img++) = 'M';
            // *(img++) = '0' + num;
            // *(img++) = '=';
            // *(img++) = transp;
            // *(img++) = 0x21 + imgwidth;
            // *(img++) = 0x21 + imgheight;
            // *(img++) = 0x21;
            // if (backfill)
            //   *(img++) = 0x21 + (1 << (imgdepth - 1)) + 1;
            // else
            //   *(img++) = 0x21 + (1 << imgdepth);

            var line = new List<byte>();
            line.Add(24);
            line.AddRange(Encoding.ASCII.GetBytes($"IM={num}="));
            line.Add((byte)transp);
            line.Add((byte)(0x21 + imgwidth));
            line.Add((byte)(0x21 + imgheight));

            // color entries
            line.Add((byte)(0x21 + (p.Length >> 6))); // bits (128, 64)
            line.Add((byte)(0x21 + (p.Length & ~192))); // bits (32, 16, 8, 4, 2, 1)

            // line.Add(0x21);
            //line.Add((byte)(0x21 + (backfill ? (1 << (imgdepth - 1)) + 1 : 1 << imgdepth)));

            byte img = 0;
            var bytesleft = 0;
            var bitsleft = 7;
            var y = 10;
            var x = 0;
            byte e = 0;

            for (x = 0; x < p.Length; x++)
            {
                for (var c = 0; c < 3; c++)
                {
                    img |= (byte)(p[x][c] >> (8 - bitsleft));
                    
                    e = encodebits(ref img, bytesleft);
                    line.Add(img);
                    // img += e;
                    y += e;
                    bitsleft -= 1;
                    img = (byte)((p[x][c] << bitsleft) & 0x7f);
                    if (bitsleft == 0)
                    {
                        img = (byte)(p[x][c] & 0x7f);
                        e = encodebits(ref img, bytesleft);
                        img += e;
                        y += e;
                        bitsleft = 7;
                    }
                }
            }


//             for (x = 0; x < ((1 << imgdepth) + (backfill ? 1 : 0)) * 3; x++)
//             {
//                 // *img = *img | (p[x] >> (8 - bitsleft));
//                 img |= (byte)(p[x][0] >> (8 - bitsleft));
// /*
//       if (*img < 0x50)
//         *img = *img + 0x20;
//       else
//         *img = *img + 0x51;
//       img++;
// */
//                 e = encodebits(ref img, bytesleft);
//                 line.Add(img);
//                 line.Add(e);
//                 // img += e;
//                 y += e;
//                 bitsleft -= 1;
//                 //*img = (p[x] << bitsleft) & 0x7f;
//                 if (bitsleft == 0)
//                 {
//                     //*img = p[x] & 0x7f;
//                     e = encodebits(ref img, bytesleft);
//                     img += e;
//                     y += e;
//                     bitsleft = 7;
//                 }
//             }

            if (bitsleft < 7)
            {
                e = encodebits(ref img, bytesleft);
                line.Add(img);
                y += e;
            }
            // *(img++) = 0;
            // *stringlen = y;
            // nttypes++;

            line.Add(0);
            toolTypes.Add(line.ToArray());

            // bitsleft = 0;
            // bytesleft = 0;
            // for (y = 0; y < imgheight; y++)
            //   for (x = 0; x < imgwidth; x++)
            //   // for (x = imgwidth - 1; x >= 0; x--)
            //     {
            //       if (bytesleft == 0 && bitsleft < imgdepth)
            //         {
            //           // *(img++) = 0;
            //           // *(img++) = 0;
            //           // *(img++) = 0;
            //           // stringlen = img;
            //           *(img++) = 'X';
            //           *(img++) = 'I';
            //           *(img++) = 'M';
            //           *(img++) = '0' + num;
            //           *(img++) = '=';
            //           *img = 0;
            //           bitsleft = 7;
            //           bytesleft = 122;
            //         }
            //       if (bitsleft == 0)
            //         {
            //           e = encodebits(img, bytesleft);
            //           img += e;
            //           *img = 0;
            //           bitsleft = 7;
            //           bytesleft--;
            //         }
            //
            //       px = pixel[x][y];
            //       if (bitsleft < imgdepth)
            //         {
            //           *img = *img | (px >> (imgdepth - bitsleft));
            //           bitsleft = bitsleft + 7;
            //           e = encodebits(img, bytesleft);
            //           img += e;
            //           *img = 0;
            //           bytesleft--;
            //         }
            //       bitsleft = bitsleft - imgdepth;
            //       *img = *img | ((px << bitsleft) & 0x7f);
            //
            //       if (bytesleft == 0 && bitsleft < imgdepth)
            //         {
            //           *stringlen = 128 - bytesleft;
            //           e = encodebits(img, bytesleft);
            //           img += e;
            //           *(img++) = 0;
            //           nttypes++;
            //           bitsleft = 0;
            //         }
            //     }
            //
            // if (bytesleft > 0)
            //   {
            //     *stringlen = 128 - bytesleft;
            //     e = encodebits(img, bytesleft);
            //     img += e;
            //     *(img++) = 0;
            //     nttypes++;
            //   }
            // return img;
        }
    }
}