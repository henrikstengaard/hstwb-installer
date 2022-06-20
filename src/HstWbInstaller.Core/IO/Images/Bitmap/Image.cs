#nullable enable
namespace HstWbInstaller.Core.IO.Images.Bitmap
{
    using System;

    public abstract class Image
    {
        public int Width { get; protected init; }
        public int Height { get; protected init; }
        public int BitsPerPixel { get; protected init; }
        public int Scanline { get; protected init; }

        public Color[] Palette { get; protected init; }
        public byte[] Data { get; protected init; }

        protected Image()
        {
            Palette = Array.Empty<Color>();
            Data = Array.Empty<byte>();
        }

        public Pixel GetPixel(int x, int y)
        {
            if (BitsPerPixel < 8)
            {
                throw new NotSupportedException();
            }

            var offset = Scanline * (Height - y - 1) + x;
            if (BitsPerPixel == 8)
            {
                var paletteColor = Data[offset];
                var color = Palette[paletteColor];
                return new Pixel
                {
                    R = color.R,
                    G = color.G,
                    B = color.B,
                    A = color.A,
                    PaletteColor = paletteColor
                };
            }

            offset *= BitsPerPixel / 8;

            return new Pixel
            {
                R = Data[offset],
                G = Data[offset + 1],
                B = Data[offset + 2],
                A = BitsPerPixel == 32 ? Data[offset + 3] : 0,
                PaletteColor = 0
            };
        }

        public void SetPixel(int x, int y, int paletteColor)
        {
            if (BitsPerPixel != 8)
            {
                throw new NotSupportedException();
            }

            var offset = (Height - y - 1) * Scanline + x;
            Data[offset] = (byte)paletteColor;
        }

        public void SetPixel(int x, int y, int r, int g, int b, int a = 255)
        {
            SetPixel(x, y, new Pixel
            {
                R = r,
                G = g,
                B = b,
                A = a
            });
        }

        public void SetPixel(int x, int y, Pixel pixel)
        {
            var offset = (Scanline * y) + x * (BitsPerPixel / 8);

            Data[offset] = (byte)pixel.R;
            Data[offset + 1] = (byte)pixel.G;
            Data[offset + 2] = (byte)pixel.B;

            if (BitsPerPixel <= 24)
            {
                return;
            }

            Data[offset + 3] = (byte)pixel.A;
        }
    }
}