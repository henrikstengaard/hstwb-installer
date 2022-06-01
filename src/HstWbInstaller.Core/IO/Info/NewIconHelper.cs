namespace HstWbInstaller.Core.IO.Info
{
    using SixLabors.ImageSharp;
    using SixLabors.ImageSharp.PixelFormats;

    public static class NewIconHelper
    {
        public static Image<Rgba32> ConvertToImage(NewIcon newIcon)
        {
            var pixelData = new byte[newIcon.Width * newIcon.Height * 4];

            var offset = 0;
            for (var y = 0; y < newIcon.Height; y++)
            {
                for (var x = 0; x < newIcon.Width; x++)
                {
                    var pixel = newIcon.ImagePixels[x][y];
                    var color = newIcon.Palette[pixel];
                    
                    pixelData[offset] = color[0]; // r
                    pixelData[offset + 1] = color[1]; // g
                    pixelData[offset + 2] = color[2]; // b
                    pixelData[offset + 3] = color[3]; // a
                    
                    offset += 4;
                }
            }

            return Image.LoadPixelData<Rgba32>(pixelData, newIcon.Width, newIcon.Height);
        }
    }
}