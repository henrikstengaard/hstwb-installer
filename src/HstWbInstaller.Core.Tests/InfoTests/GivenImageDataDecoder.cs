namespace HstWbInstaller.Core.Tests.InfoTests
{
    using System.IO;
    using System.Linq;
    using System.Threading.Tasks;
    using IO.Info;
    using SixLabors.ImageSharp;
    using SixLabors.ImageSharp.PixelFormats;
    using Xunit;

    public class GivenImageDataDecoder : InfoTestBase
    {
        [Fact]
        public void WhenDecodeImageDataWith2DifferentColorsUsedThenRgbaPixelDataMatchesPixelSet()
        {
            // arrange - set dimension, depth, palette for image to encode
            var width = 2;
            var height = 2;
            var depth = 2;
            var palette = AmigaOs31Palette.FourColors.ToArray();

            // arrange - create expected pixel data
            var pixelData = TestDataHelper.CreatePixelData(width, height);

            // arrange - set pixel x = 1, y = 1 set to palette color 0
            TestDataHelper.SetPixelDataPixel(pixelData, width, 0, 0, palette[0][0], palette[0][1], palette[0][2],
                palette[0][3]);

            // arrange - set pixel x = 2, y = 1 set to palette color 0
            TestDataHelper.SetPixelDataPixel(pixelData, width, 1, 0, palette[0][0], palette[0][1], palette[0][2],
                palette[0][3]);

            // arrange - set pixel x = 1, y = 2 set to palette color 0
            TestDataHelper.SetPixelDataPixel(pixelData, width, 0, 1, palette[0][0], palette[0][1], palette[0][2],
                palette[0][3]);

            // arrange - set pixel x = 2, y = 2 set to palette color 3
            TestDataHelper.SetPixelDataPixel(pixelData, width, 1, 1, palette[3][0], palette[3][1], palette[3][2],
                palette[0][3]);

            // arrange - load image from pixel data
            var expectedImage = Image.LoadPixelData<Rgba32>(pixelData, width, height);

            // arrange - create image data
            var imageData = new ImageData
            {
                Width = (short)width,
                Height = (short)height,
                Depth = (short)depth,
                Data = TestDataHelper.CreateImageData(width, height, depth)
            };

            // arrange - set pixel x = 2, y = 2 set to palette color 3
            // note other pixels are set to 0 resulting in color 0
            TestDataHelper.SetImageDataPixel(imageData.Data, width, height, depth, 1, 1, 3);

            // act - decode image data
            var image = ImageDataDecoder.Decode(imageData, palette);

            // assert - image matches pixels set
            AssertEqual(expectedImage, image);
        }

        [Fact]
        public void WhenDecodeImageDataWith3DifferentColorsUsedThenRgbaPixelDataMatchesPixelSet()
        {
            // arrange - set dimension, depth, palette for image to encode
            var width = 2;
            var height = 2;
            var depth = 2;
            var palette = AmigaOs31Palette.FourColors.ToArray();

            // arrange - create expected pixel data
            var pixelData = TestDataHelper.CreatePixelData(width, height);

            // arrange - set pixel x = 1, y = 1 set to palette color 0
            TestDataHelper.SetPixelDataPixel(pixelData, width, 0, 0, palette[0][0], palette[0][1], palette[0][2],
                palette[0][3]);

            // arrange - set pixel x = 2, y = 1 set to palette color 0
            TestDataHelper.SetPixelDataPixel(pixelData, width, 1, 0, palette[0][0], palette[0][1], palette[0][2],
                palette[0][3]);

            // arrange - set pixel x = 1, y = 2 set to palette color 2
            TestDataHelper.SetPixelDataPixel(pixelData, width, 0, 1, palette[2][0], palette[2][1], palette[2][2],
                palette[2][3]);

            // arrange - set pixel x = 2, y = 2 set to palette color 3
            TestDataHelper.SetPixelDataPixel(pixelData, width, 1, 1, palette[3][0], palette[3][1], palette[3][2],
                palette[0][3]);

            // arrange - load image from pixel data
            var expectedImage = Image.LoadPixelData<Rgba32>(pixelData, width, height);

            // arrange - create image data
            // note all pixels in image data are set to 0 resulting in color 0
            var imageData = new ImageData
            {
                Width = (short)width,
                Height = (short)height,
                Depth = (short)depth,
                Data = TestDataHelper.CreateImageData(width, height, depth)
            };

            // arrange - set pixel x = 1, y = 2 set to palette color 2
            TestDataHelper.SetImageDataPixel(imageData.Data, width, height, depth, 0, 1, 2);

            // arrange - set pixel x = 2, y = 2 set to palette color 3
            TestDataHelper.SetImageDataPixel(imageData.Data, width, height, depth, 1, 1, 3);

            // act - decode image data
            var image = ImageDataDecoder.Decode(imageData, palette);

            // assert - image matches pixels set
            AssertEqual(expectedImage, image);
        }

        [Fact]
        public async Task Test()
        {
            var infoPath = @"TestData\Info\GhostsNGoblins.info";
            await using var stream = File.OpenRead(infoPath);
            var diskObject = await DiskObjectReader.Read(stream);
            var decoder = new NewIconToolTypesDecoder(diskObject.ToolTypes.TextDatas);
            var newIcon = decoder.Decode(1);
        }
    }
}