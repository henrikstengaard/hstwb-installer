namespace HstWbInstaller.Core.IO.Info
{
    using System;
    using System.Collections.Generic;
    using SixLabors.ImageSharp;
    using SixLabors.ImageSharp.PixelFormats;

    public static class NewIconEncoder
    {
        private const int MaxNewIconColors = 255;
        
        public static NewIcon Encode(Image<Rgba32> image)
        {
            var palette = new List<byte[]>();
            var paletteIndex = new Dictionary<string, int>();

            var transparentColor = -1;

            var imagePixels = new byte[image.Width * image.Height];

            image.ProcessPixelRows(accessor =>
            {
                // Color is pixel-agnostic, but it's implicitly convertible to the Rgba32 pixel type
                //Rgba32 transparent = Color.Transparent;

                var offset = 0;
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

                        if (pixel.Equals(Color.Transparent))
                        {
                            transparentColor = color;
                        }
                        
                        imagePixels[offset++] = (byte)color;
                    }
                }
            });

            if (palette.Count > MaxNewIconColors)
            {
                throw new ArgumentException(
                    $"Image has {palette.Count} colors and NewIcon only allows max {MaxNewIconColors} colors",
                    nameof(image));
            }

            // switch transparent color to first palette entry, if present and higher than 0
            if (transparentColor > 0)
            {
                // get transparent color
                var transparentColorR = palette[transparentColor][0];
                var transparentColorG = palette[transparentColor][1];
                var transparentColorB = palette[transparentColor][2];
                var transparentColorA = palette[transparentColor][3];
                
                // move first palette entry to transparent color entry
                palette[transparentColor][0] = palette[0][0];
                palette[transparentColor][1] = palette[1][0];
                palette[transparentColor][2] = palette[2][0];
                palette[transparentColor][3] = palette[3][0];

                // set first palette entry to transparent color
                palette[0][0] = transparentColorR;
                palette[0][1] = transparentColorG;
                palette[0][2] = transparentColorB;
                palette[0][3] = transparentColorA;
            }
            
            return new NewIcon
            {
                Width = (short)image.Width,
                Height = (short)image.Height,
                Transparent = transparentColor >= 0,
                Depth = (int)Math.Ceiling(Math.Log(palette.Count) / Math.Log(2)),
                Palette = palette.ToArray(),
                ImagePixels = imagePixels
            };
        }
    }
}