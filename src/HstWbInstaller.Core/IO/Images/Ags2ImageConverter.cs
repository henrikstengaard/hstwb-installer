namespace HstWbInstaller.Core.IO.Images
{
    using System;
    using System.Collections.Generic;
    using System.Drawing;
    using System.Drawing.Imaging;

    public static class Ags2ImageConverter
    {
        public static System.Drawing.Bitmap ConvertToAgs2BackgroundImage(System.Drawing.Bitmap image, PixelFormat format, Color textColor, Color backgroundColor)
        {
            if (!(format is PixelFormat.Format8bppIndexed or PixelFormat.Format4bppIndexed))
            {
                throw new ArgumentException("Only 8bpp and 4bpp pixel formats are supported by AGS2", nameof(format));
            }
            
            var backgroundColorKey = GetColorKey(backgroundColor);
            var textColorKey = GetColorKey(textColor);

            if (backgroundColorKey == textColorKey)
            {
                throw new ArgumentException("Text and background color can not be the same", nameof(textColor));
            }
            
            var ags2Image = new System.Drawing.Bitmap(image.Width, image.Height, format);
            
            // clear palette
            var ags2Palette = ags2Image.Palette;
            for (var i = 0; i < ags2Palette.Entries.Length; i++)
            {
                ags2Palette.Entries[i] = Color.FromArgb(0,0,0,0);
            }

            // set ags2 text and background colors
            var lastPaletteEntry = format == PixelFormat.Format8bppIndexed ? 255 : 15;
            ags2Palette.Entries[lastPaletteEntry - 1] = backgroundColor;
            ags2Palette.Entries[lastPaletteEntry] = textColor;

            var bitmapLocker = new BitmapLocker(image);
            bitmapLocker.Lock();
            
            var ags2ImageLocker = new BitmapLocker(ags2Image);
            ags2ImageLocker.Lock();

            var paletteMap = new Dictionary<string, int>
            {
                { backgroundColorKey, lastPaletteEntry - 1},
                { textColorKey, lastPaletteEntry}
            };
            
            for (var y = 0; y < image.Height; y++)
            {
                for (var x = 0; x < image.Width; x++)
                {
                    var color = bitmapLocker.GetPixel(x, y);
                    var colorKey = GetColorKey(color);
            
                    if (!paletteMap.ContainsKey(colorKey))
                    {
                        var ags2PaletteIndex = lastPaletteEntry - paletteMap.Count;
                        paletteMap[colorKey] = ags2PaletteIndex;
                        ags2Palette.Entries[ags2PaletteIndex] = color;
                    }
                    
                    ags2ImageLocker.SetPixel(x, y, paletteMap[colorKey]);
                }
            }

            ags2Image.Palette = ags2Palette;
            
            bitmapLocker.Unlock();
            ags2ImageLocker.Unlock();

            return ags2Image;
        }

        private static string GetColorKey(Color color) => $"{color.R},{color.G},{color.B},{color.A}";
    }
}