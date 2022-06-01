namespace HstWbInstaller.Core.IO.Info
{
    using System;
    using System.Collections.Generic;
    using System.Linq;
    using SixLabors.ImageSharp;
    using SixLabors.ImageSharp.PixelFormats;

    public static class ImageDataEncoder
    {
        public static ImageData Encode(Image<Rgba32> image, int depth = 3)
        {
            var maxColors = Math.Pow(2, depth);
            var palette = new List<byte[]>();
            var paletteIndex = new Dictionary<string, int>();

            const int bitsPerByte = 8;
            var bytesPerRow = (image.Width + 15) / 16 * 2;

            var data = new byte[bytesPerRow * image.Height * depth];

            image.ProcessPixelRows(accessor =>
            {
                // Color is pixel-agnostic, but it's implicitly convertible to the Rgba32 pixel type
                //Rgba32 transparent = Color.Transparent;

                for (int y = 0; y < accessor.Height; y++)
                {
                    Span<Rgba32> pixelRow = accessor.GetRowSpan(y);

                    // pixelRow.Length has the same value as accessor.Width,
                    // but using pixelRow.Length allows the JIT to optimize away bounds checks:
                    for (int x = 0; x < pixelRow.Length; x++)
                    {
                        // get a reference to the pixel at position x
                        ref Rgba32 pixel = ref pixelRow[x];

                        var colorId = pixel.ToHex();
                        if (!paletteIndex.ContainsKey(colorId))
                        {
                            palette.Add(new[] { pixel.R, pixel.G, pixel.B, pixel.A });
                            paletteIndex[colorId] = palette.Count - 1;
                        }

                        var color = paletteIndex[colorId];

                        for (var plane = 0; plane < depth; plane++)
                        {
                            var bit = 7 - (x % bitsPerByte);
                            var offset = (bytesPerRow * image.Height * plane) + (y * bytesPerRow) + (x / bitsPerByte);

                            var setBitPlane = (color & (1 << plane)) != 0;
                            if (setBitPlane)
                            {
                                data[offset] |= (byte)(1 << bit);
                            }
                        }
                    }
                }
            });

            if (palette.Count > maxColors)
            {
                throw new ArgumentException(
                    $"Image has {palette.Count} colors, but depth {depth} only allows max {maxColors} colors",
                    nameof(depth));
            }

            return new ImageData
            {
                TopEdge = 0,
                LeftEdge = 0,
                Width = (short)image.Width,
                Height = (short)image.Height,
                Depth = (byte)depth,
                Data = data,
                ImageDataPointer = 1,
                PlanePick = (byte)(maxColors - 1)
            };
        }

        /// <summary>
        /// encodes image into image data. colors not present in palette are ignored/skipped
        /// </summary>
        /// <param name="image"></param>
        /// <param name="palette"></param>
        /// <param name="depth"></param>
        /// <returns></returns>
        /// <exception cref="ArgumentException"></exception>
        public static ImageData Encode(Image<Rgba32> image, byte[][] palette, int depth = 3)
        {
            var maxColors = Math.Pow(2, depth);

            if (palette.Length > maxColors)
            {
                throw new ArgumentException(
                    $"Image has {palette.Length} colors, but depth {depth} only allows max {maxColors} colors",
                    nameof(depth));
            }

            var paletteIndex = new Dictionary<string, int>();
            for (var i = 0; i < palette.Length; i++)
            {
                paletteIndex[string.Join(string.Empty, palette[i].Select(c => c.ToString("x2"))).ToLower()] = i;
            }

            const int bitsPerByte = 8;
            var bytesPerRow = (image.Width + 15) / 16 * 2;

            var data = new byte[bytesPerRow * image.Height * depth];

            image.ProcessPixelRows(accessor =>
            {
                // Color is pixel-agnostic, but it's implicitly convertible to the Rgba32 pixel type
                //Rgba32 transparent = Color.Transparent;

                for (int y = 0; y < accessor.Height; y++)
                {
                    Span<Rgba32> pixelRow = accessor.GetRowSpan(y);

                    // pixelRow.Length has the same value as accessor.Width,
                    // but using pixelRow.Length allows the JIT to optimize away bounds checks:
                    for (int x = 0; x < pixelRow.Length; x++)
                    {
                        // get a reference to the pixel at position x
                        ref Rgba32 pixel = ref pixelRow[x];

                        var colorId = pixel.ToHex().ToLower();
                        if (!paletteIndex.ContainsKey(colorId))
                        {
                            continue;
                        }

                        var color = paletteIndex[colorId];

                        for (var bitPlane = 0; bitPlane < depth; bitPlane++)
                        {
                            var colorBit = color & (1 << bitPlane);
                            if (colorBit == 0)
                            {
                                continue;
                            }
                            
                            var bitOffset = 7 - (x % bitsPerByte);
                            var imageDataOffset = (bytesPerRow * image.Height * bitPlane) + (y * bytesPerRow) + (x / bitsPerByte);
                            data[imageDataOffset] |= (byte)(1 << bitOffset);
                        }
                    }
                }
            });

            return new ImageData
            {
                TopEdge = 0,
                LeftEdge = 0,
                Width = (short)image.Width,
                Height = (short)image.Height,
                Depth = (byte)depth,
                ImageDataPointer = 1,
                PlanePick = (byte)(maxColors - 1),
                PlaneOnOff = 0,
                NextPointer = 0,
                Data = data,
            };
        }
    }
}