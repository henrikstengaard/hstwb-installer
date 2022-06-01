namespace HstWbInstaller.Core.Tests.InfoTests
{
    using System;
    using System.Collections.Generic;
    using System.Linq;
    using IO.Info;
    using SixLabors.ImageSharp;
    using SixLabors.ImageSharp.PixelFormats;
    using Xunit;

    public static class TestDataHelper
    {
        private const int RgbaColorSize = 4;
        public const int Depth = 2; // depth of 2 is used to represent 4 colors ([Math]::Pow(2, depth) = max colors)

        public static byte[][] Palette => AmigaOs31Palette.FourColors.ToArray();
        
        public static byte[] CreateImageData(int width, int height, int depth)
        {
            var bytesPerRow = (width + 15) / 16 * 2;
            return new byte[bytesPerRow * height * depth];
        }

        public static void SetImageDataPixel(byte[] imageData, int width, int height, int depth, int x, int y, int color)
        {
            var bytesPerRow = (width + 15) / 16 * 2;
            
            for (var bitPlane = 0; bitPlane < depth; bitPlane++)
            {
                var colorBit = color & (1 << bitPlane);
                if (colorBit == 0)
                {
                    continue;
                }
                            
                var bitOffset = 7 - (x % Constants.BITS_PER_BYTE);
                var imageDataOffset = (bytesPerRow * height * bitPlane) + (y * bytesPerRow) + (x / Constants.BITS_PER_BYTE);
                imageData[imageDataOffset] |= (byte)(1 << bitOffset);
            }
        }
        
        public static byte[] CreatePixelData(int width, int height)
        {
            return new byte[width * height * RgbaColorSize];
        }
        
        public static Image<Rgba32> CreateImage(byte[][] palette)
        {
            var width = 8;
            var height = 8;
            var pixelData = new byte[width * height * RgbaColorSize];

            for (var y = 0; y < 4; y++)
            {
                for (var x = 0; x < 4; x++)
                {
                    SetPixelDataPixel(pixelData, width, x, y, palette[0][0], palette[0][1], palette[0][2], palette[0][3]);
                    SetPixelDataPixel(pixelData, width, 4 + x, y, palette[1][0], palette[1][1], palette[1][2], palette[1][3]);
                    SetPixelDataPixel(pixelData, width, x, 4 + y, palette[2][0], palette[2][1], palette[2][2], palette[2][3]);
                    SetPixelDataPixel(pixelData, width, 4 + x, 4 + y, palette[3][0], palette[3][1], palette[3][2], palette[3][3]);
                }
            }

            return Image.LoadPixelData<Rgba32>(pixelData, width, height);
        }

        public static ImageData CreateImageData()
        {
            var width = 8;
            var height = 8;
            var depth = 2;
            var imageData = CreateImageData(width, height, depth);

            for (var y = 0; y < 4; y++)
            {
                for (var x = 0; x < 4; x++)
                {
                    SetImageDataPixel(imageData, width, height, depth, x, y, 0);
                    SetImageDataPixel(imageData, width, height, depth, 4 + x, y, 1);
                    SetImageDataPixel(imageData, width, height, depth, x, 4 + y, 2);
                    SetImageDataPixel(imageData, width, height, depth, 4 + x, 4 + y, 3);
                }
            }

            return new ImageData
            {
                Width = (short)width,
                Height = (short)height,
                Depth = (short)depth,
                TopEdge = 0,
                LeftEdge = 0,
                NextPointer = 0,
                PlanePick = (byte)(Math.Pow(2, depth) - 1),
                PlaneOnOff = 0,
                ImageDataPointer = 1,
                Data = imageData
            };
        }
        
        public static Image<Rgba32> CreateFirstImage()
        {
            return CreateImage(Palette.ToArray());
        }
        
        public static Image<Rgba32> CreateSecondImage()
        {
            var palette = new List<byte[]>(Palette).ToArray();
            Array.Reverse(palette);
            
            return CreateImage(palette);
        }

        public static void SetPixelDataPixel(byte[] pixelData, int width, int x, int y, byte r, byte g, byte b, byte a)
        {
            var offset = ((y * width) + x) * RgbaColorSize;
            pixelData[offset] = r;
            pixelData[offset + 1] = g;
            pixelData[offset + 2] = b;
            pixelData[offset + 3] = a;
        }
    }
}