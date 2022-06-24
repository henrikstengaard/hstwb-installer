namespace HstWbInstaller.Core.IO.Info
{
    using Images.Bitmap;
    using SixLabors.ImageSharp;
    using SixLabors.ImageSharp.PixelFormats;
    using Color = Images.Bitmap.Color;
    using Image = SixLabors.ImageSharp.Image;

    public static class ColorIconConverter
    {
        public static BitmapImage ToBitmap8Bpp(ColorIconImage colorIconImage)
        {
            var bitsPerPixel = 8;
            var scanline = ((bitsPerPixel * colorIconImage.Width + 31) / 32) * 4;

            var palette = new Color[256];
            for (var i = 0; i < palette.Length; i++)
            {
                palette[i] = new Color();
                if (i >= colorIconImage.Palette.Length)
                {
                    continue;
                }

                palette[i].R = colorIconImage.Palette[i].R;
                palette[i].G = colorIconImage.Palette[i].G;
                palette[i].B = colorIconImage.Palette[i].B;
                palette[i].A = colorIconImage.Palette[i].A;
            }
            
            var pixelData = new byte[scanline * colorIconImage.Height];

            var imagePixelsOffset = 0;
            for (var y = 0; y < colorIconImage.Height; y++)
            {
                for (var x = 0; x < colorIconImage.Width; x++)
                {
                    var palent = de_get_bits_symbol(colorIconImage.Pixels, 8, y*colorIconImage.Width, x);                    
                    var paletteColor = colorIconImage.Pixels[imagePixelsOffset++];

                    if (palent != paletteColor)
                    {
                        
                    }
                    
                    pixelData[scanline * (colorIconImage.Height - y - 1) + x] = (byte)paletteColor;
                }
            }

            return new BitmapImage(colorIconImage.Width, colorIconImage.Height, bitsPerPixel, palette, pixelData);
        }

        public static BitmapImage ToBitmap32Bpp(ColorIconImage colorIconImage)
        {
            var bitsPerPixel = 32;
            var scanline = ((bitsPerPixel * colorIconImage.Width + 31) / 32) * 4;

            var pixelData = new byte[scanline * colorIconImage.Height];

            var imagePixelsOffset = 0;
            for (var y = 0; y < colorIconImage.Height; y++)
            {
                for (var x = 0; x < colorIconImage.Width; x++)
                {
                    var paletteColor = colorIconImage.Pixels[imagePixelsOffset++];

                    var color = colorIconImage.Palette[paletteColor];

                    var pixelDataOffset = scanline * (colorIconImage.Height - y - 1) + (x * 4);
                    pixelData[pixelDataOffset] = (byte)color.B;
                    pixelData[pixelDataOffset + 1] = (byte)color.G;
                    pixelData[pixelDataOffset + 2] = (byte)color.R;
                    pixelData[pixelDataOffset + 3] = (byte)color.A;
                }
            }

            return new BitmapImage(colorIconImage.Width, colorIconImage.Height, bitsPerPixel, data: pixelData);
        }

        public static Image<Rgba32> ToImage(ColorIconImage colorIconImage)
        {
            var pixelData = new byte[colorIconImage.Width * colorIconImage.Height * 4];

            var imagePixelsOffset = 0;
            var pixelDataOffset = 0;
            for (var y = 0; y < colorIconImage.Height; y++)
            {
                for (var x = 0; x < colorIconImage.Width; x++)
                {
                    var paletteColor = colorIconImage.Pixels[imagePixelsOffset++];

                    var color = colorIconImage.Palette[paletteColor];

                    pixelData[pixelDataOffset] = (byte)color.R;
                    pixelData[pixelDataOffset + 1] = (byte)color.G;
                    pixelData[pixelDataOffset + 2] = (byte)color.B;
                    pixelData[pixelDataOffset + 3] = (byte)color.A;

                    pixelDataOffset += 4;
                }
            }

            return Image.LoadPixelData<Rgba32>(pixelData, colorIconImage.Width, colorIconImage.Height);
        }
        
        private static byte de_get_bits_symbol(byte[] f, int bps, int rowstart, int index)
        {
            int byte_offset;
            byte b;
            byte x = 0;

            switch(bps) {
                case 1:
                    byte_offset = rowstart + index/8;
                    b = f[byte_offset];
                    x = (byte)((b >> (7 - index%8)) & 0x01);
                    break;
                case 2:
                    byte_offset = rowstart + index/4;
                    b = f[byte_offset];
                    x = (byte)((b >> (2 * (3 - index%4))) & 0x03);
                    break;
                case 4:
                    byte_offset = rowstart + index/2;
                    b = f[byte_offset];
                    x = (byte)((b >> (4 * (1 - index%2))) & 0x0f);
                    break;
                case 8:
                    byte_offset = rowstart + index;
                    x = f[byte_offset];
                    break;
            }
            return x;
        }
    }
}