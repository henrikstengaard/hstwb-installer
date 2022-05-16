namespace HstWbInstaller.Core.IO.Info
{
    using System.Collections.Generic;
    using SixLabors.ImageSharp;
    using SixLabors.ImageSharp.PixelFormats;

    public static class ImageDataConverter
    {
        public static Image<Rgba32> ConvertToImage(ImageData imageData)
        {
            return ConvertToImage(imageData, AmigaOs31Palette.FourColors);
        }

        public static Image<Rgba32> ConvertToImage(ImageData imageData, IList<byte[]> palette)
        {
            var bitsPerByte = 8;
            var bytesPerRow = (imageData.Width + 15) / 16 * 2;

            var image = new byte[imageData.Width * imageData.Height];

            var plane = 0;

            var xOffset = 0;
            var y = 0;
            for (var i = 0; i < imageData.Data.Length; i++)
            {
                // loop each byte
                // each byte represent 8 pixels horizontally
                for (var bit = 0; bit < bitsPerByte; bit++)
                {
                    var x = xOffset + bit;
                    var color = ((imageData.Data[i] >> (7 - bit)) & 1) << plane;

                    if (x < imageData.Width)
                    {
                        image[y * imageData.Width + x] |= (byte)color;
                    }
                }

                xOffset += 8;

                if (xOffset >= bytesPerRow * 8)
                {
                    y++;
                    xOffset = 0;
                }

                if (y >= imageData.Height)
                {
                    y = 0;
                    plane++;
                }
            }
            
            var imageRgbaData = new byte[imageData.Width * imageData.Height * 4]; // rgba

            var tx = 0;
            var ty = 0;
            for (var i = 0; i < image.Length; i++)
            {
                var srcOffset = ty * imageData.Width + tx;
                var destOffset = srcOffset * 4;

                var color = image[i];
                if (color >= palette.Count)
                {
                    color = 0;
                }
                
                imageRgbaData[destOffset + 0] = palette[color][0];
                imageRgbaData[destOffset + 1] = palette[color][1];
                imageRgbaData[destOffset + 2] = palette[color][2];
                imageRgbaData[destOffset + 3] = palette[color][3];

                tx++;
                if (tx < imageData.Width)
                {
                    continue;
                }
                tx = 0;
                ty++;
            }

            return Image.LoadPixelData<Rgba32>(imageRgbaData, imageData.Width, imageData.Height);
        }
    }
}