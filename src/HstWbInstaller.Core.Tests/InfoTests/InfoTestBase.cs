namespace HstWbInstaller.Core.Tests.InfoTests
{
    using System;
    using IO.Images.Bitmap;
    using IO.Info;
    using SixLabors.ImageSharp;
    using SixLabors.ImageSharp.PixelFormats;
    using Xunit;

    public abstract class InfoTestBase
    {
        protected static void AssertEqual(BitmapImage source, NewIcon destination)
        {
            Assert.Equal(source.Width, destination.Width);
            Assert.Equal(source.Height, destination.Height);

            for (var i = 0; i < Math.Min(source.Palette.Length, destination.Palette.Length); i++)
            {
                var sourceColor = source.Palette[i];
                var destinationColor = destination.Palette[i];
                
                Assert.Equal(sourceColor.R, destinationColor[0]);
                Assert.Equal(sourceColor.G, destinationColor[1]);
                Assert.Equal(sourceColor.B, destinationColor[2]);
            }
            
            for (var y = 0; y < source.Height; y++)
            {
                for (var x = 0; x < source.Width; x++)
                {
                    var sourcePixel = source.GetPixel(x, y);
                    var destinationColor = destination.ImagePixels[destination.Width * y + x];
                    
                    Assert.Equal(sourcePixel.PaletteColor, destinationColor);
                }
            }
        }

        protected static void AssertEqual(Image<Rgba32> source, NewIcon destination)
        {
            Assert.Equal(source.Width, destination.Width);
            Assert.Equal(source.Height, destination.Height);

            for (int y = 0; y < source.Height; y++)
            {
                for (int x = 0; x < source.Width; x++)
                {
                    var destinationColor = destination.ImagePixels[destination.Width * y + x];
                    var color = destination.Palette[destinationColor];
                    Assert.Equal(source[x, y].R, color[0]);
                    Assert.Equal(source[x, y].G, color[1]);
                    Assert.Equal(source[x, y].B, color[2]);
                }
            }
        }
        
    }
}