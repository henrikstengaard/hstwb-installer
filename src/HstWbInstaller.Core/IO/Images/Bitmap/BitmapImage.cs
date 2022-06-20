#nullable enable
namespace HstWbInstaller.Core.IO.Images.Bitmap
{
    using System;
    using System.Collections.Generic;
    using System.Linq;

    public class BitmapImage : Image
    {
        public BitmapImage(int width, int height, int bitsPerPixel, IEnumerable<Color>? palette = null,
            IEnumerable<byte>? data = null)
        {
            Width = width;
            Height = height;
            BitsPerPixel = bitsPerPixel;
            
            if (bitsPerPixel != 1 && bitsPerPixel != 4 && bitsPerPixel != 8 && bitsPerPixel != 24 && bitsPerPixel != 32)
            {
                throw new ArgumentException($"{bitsPerPixel} bits per pixel is not supported", nameof(bitsPerPixel));
            }
            
            // Each scan line is zero padded to the nearest 4-byte boundary. If the image has a width that is not divisible by four, say, 21 bytes, there would be 3 bytes of padding at the end of every scan line.
            Scanline = ((bitsPerPixel * width + 31) / 32) * 4;

            if (data != null)
            {
                var dataArray = data as byte[] ?? data.ToArray();
                if (dataArray.Length != Scanline * height)
                {
                    throw new ArgumentException($"Data does not match size {Scanline * height}", nameof(data));
                }

                Data = dataArray;
            }
            else
            {
                Data = new byte[Scanline * height];
            }

            if (palette != null)
            {
                Palette = palette as Color[] ?? palette.ToArray();
            }
            else
            {
                Palette = Array.Empty<Color>();
            }
        }
    }
}