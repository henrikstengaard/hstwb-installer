namespace HstWbInstaller.Core.Tests.ImageTests
{
    using SixLabors.ImageSharp;
    using SixLabors.ImageSharp.PixelFormats;
    using Xunit;

    public static class ImageTestHelper
    {
        public static void AssertEqual(Image<Rgba32> source, Image<Rgba32> destination)
        {
            Assert.Equal(source.Width, destination.Width);
            Assert.Equal(source.Height, destination.Height);

            for (int y = 0; y < source.Height; y++)
            {
                for (int x = 0; x < source.Width; x++)
                {
                    Assert.Equal(source[x, y].R, destination[x, y].R);
                    Assert.Equal(source[x, y].G, destination[x, y].G);
                    Assert.Equal(source[x, y].B, destination[x, y].B);
                    Assert.Equal(source[x, y].A, destination[x, y].A);
                }
            }
        }
    }
}