namespace HstWbInstaller.Core.Tests.InfoTests
{
    using System;
    using System.Linq;
    using IO.Info;
    using SixLabors.ImageSharp;
    using SixLabors.ImageSharp.PixelFormats;
    using Xunit;

    public class GivenImageDataEncoder
    {
        [Fact]
        public void WhenEncodeRgbaPixelDataWith1PixelSetThenImageDataMatchesPixelSet()
        {
            // arrange - set dimension, depth, palette for image to encode
            var width = 2;
            var height = 2;
            var depth = 2;
            var palette = AmigaOs31Palette.FourColors.ToArray();
            
            // arrange - create expected image data with pixel x = 2, y = 2 set to palette color 3
            var expectedImageData = TestDataHelper.CreateImageData(width, height, depth);

            // arrange - set pixel x = 2, y = 2 set to palette color 3
            TestDataHelper.SetImageDataPixel(expectedImageData, width, height, depth, 1, 1, 3);
            
            // arrange - create pixel data
            var pixelData = TestDataHelper.CreatePixelData(width, height);

            // arrange - set pixel x = 2, y = 2 set to palette color 3
            TestDataHelper.SetPixelDataPixel(pixelData, width, 1, 1, palette[3][0], palette[3][1], palette[3][2], palette[3][3]);
            
            // arrange - load image from pixel data
            var image = Image.LoadPixelData<Rgba32>(pixelData, width, height);
            
            // act - encode image
            var imageData = ImageDataEncoder.Encode(image, palette, depth);
            
            // assert - image data is correct
            Assert.Equal(0, imageData.TopEdge);
            Assert.Equal(0, imageData.LeftEdge);
            Assert.Equal(width, imageData.Width);
            Assert.Equal(height, imageData.Height);
            Assert.Equal(depth, imageData.Depth);
            Assert.NotEqual(0U, imageData.ImageDataPointer);
            Assert.Equal(Math.Pow(2, depth) - 1, imageData.PlanePick);
            Assert.Equal(expectedImageData, imageData.Data);
            Assert.Equal(0U, imageData.NextPointer);
        }

        [Fact]
        public void WhenEncodeRgbaPixelDataWith2PixelsSetThenImageDataMatchesPixelSet()
        {
            // arrange - set dimension, depth, palette for image to encode
            var width = 2;
            var height = 2;
            var depth = 2;
            var palette = AmigaOs31Palette.FourColors.ToArray();
            
            // arrange - create expected image data
            var expectedImageData = TestDataHelper.CreateImageData(width, height, depth);

            // arrange - set pixel x = 1, y = 2 set to palette color 2
            TestDataHelper.SetImageDataPixel(expectedImageData, width, height, depth, 0, 1, 2);

            // arrange - set pixel x = 2, y = 2 set to palette color 2
            TestDataHelper.SetImageDataPixel(expectedImageData, width, height, depth, 1, 1, 3);
            
            // arrange - create pixel data for image
            var pixelData = TestDataHelper.CreatePixelData(width, height);

            // arrange - set pixel x = 1, y = 2 set to palette color 2
            TestDataHelper.SetPixelDataPixel(pixelData, width, 0, 1, palette[2][0], palette[2][1], palette[2][2], palette[2][3]);

            // arrange - set pixel x = 2, y = 2 set to palette color 3
            TestDataHelper.SetPixelDataPixel(pixelData, width, 1, 1, palette[3][0], palette[3][1], palette[3][2], palette[3][3]);
            
            // arrange - load image from pixel data
            var image = Image.LoadPixelData<Rgba32>(pixelData, width, height);
            
            // act - encode image
            var imageData = ImageDataEncoder.Encode(image, palette, depth);
            
            // assert - image data is correct
            Assert.Equal(0, imageData.TopEdge);
            Assert.Equal(0, imageData.LeftEdge);
            Assert.Equal(width, imageData.Width);
            Assert.Equal(height, imageData.Height);
            Assert.Equal(depth, imageData.Depth);
            Assert.NotEqual(0U, imageData.ImageDataPointer);
            Assert.Equal(Math.Pow(2, depth) - 1, imageData.PlanePick);
            Assert.Equal(expectedImageData, imageData.Data);
            Assert.Equal(0U, imageData.NextPointer);
        }
    }
}