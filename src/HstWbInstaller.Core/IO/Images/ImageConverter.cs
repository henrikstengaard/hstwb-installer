namespace HstWbInstaller.Core.IO.Images
{
    using System;
    using System.Collections.Generic;
    using System.Drawing;
    using System.Drawing.Imaging;

    public static class ImageConverter
    {
        public static int GetMaxColors(PixelFormat format) =>
            format switch
            {
                PixelFormat.Format8bppIndexed => 255,
                PixelFormat.Format4bppIndexed => 16,
                PixelFormat.Format1bppIndexed => 2,
                _ => -1
            };

        public static System.Drawing.Bitmap ConvertTo4BppIndexedImage(System.Drawing.Bitmap image, PixelFormat format)
        {
            var colorMap = new Dictionary<string, Color>();

            var destImage = new System.Drawing.Bitmap(image.Width, image.Height, format);

            var maxColors = GetMaxColors(format);
            
            var bitmapLocker = new BitmapLocker(image);
            bitmapLocker.Lock();

            var destBitmapLocker = new BitmapLocker(image);
            destBitmapLocker.Lock();
            
            for (var y = 0; y < image.Height; y++)
            {
                for (var x = 0; x < image.Width; x++)
                {
                    var color = bitmapLocker.GetPixel(x, y);
                    var key = $"{color.R},{color.G},{color.B},{color.A}";

                    if (!colorMap.ContainsKey(key))
                    {
                        if (maxColors > -1 && colorMap.Count > maxColors)
                        {
                            throw new Exception($"Too many colors for format '{format}'");
                        }
                    
                        colorMap[key] = color;
                    }
                    
                    destBitmapLocker.SetPixel(x, y, color);
                }
            }
            
            bitmapLocker.Unlock();
            destBitmapLocker.Unlock();

            return destImage;
        }
    }
}