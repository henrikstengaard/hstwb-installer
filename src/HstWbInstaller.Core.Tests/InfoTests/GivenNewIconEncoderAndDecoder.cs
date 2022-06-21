namespace HstWbInstaller.Core.Tests.InfoTests
{
    using System.IO;
    using System.Linq;
    using System.Threading.Tasks;
    using IO.Info;
    using SixLabors.ImageSharp.Formats.Png;
    using SixLabors.ImageSharp.PixelFormats;
    using Xunit;
    using Image = SixLabors.ImageSharp.Image;

    public class GivenNewIconEncoderAndDecoder : InfoTestBase
    {
        [Theory]
        [InlineData(@"TestData\Info\Floppy.png")]
        [InlineData(@"TestData\Info\Puzzle-Bubble-60-colors.png")]
        [InlineData(@"TestData\Info\Puzzle-Bubble-100-colors.png")]
        [InlineData(@"TestData\Info\Puzzle-Bubble-127-colors.png")]
        [InlineData(@"TestData\Info\Puzzle-Bubble-128-colors.png")]
        [InlineData(@"TestData\Info\Puzzle-Bubble-129-colors.png")]
        [InlineData(@"TestData\Info\Puzzle-Bubble-150-colors.png")]
        [InlineData(@"TestData\Info\Puzzle-Bubble-255-colors.png")]
        public async Task WhenEncodeAndDecodeNewIconThenNewIconAndImageAreEqual(string imagePath)
        {
            // arrange - new icon image number set to 1
            var imageNumber = 1;

            // arrange - read image
            var image = await Image.LoadAsync<Rgba32>(File.OpenRead(imagePath), new PngDecoder());

            // arrange - encode image to new icon
            var newIcon = NewIconEncoder.Encode(image);

            // act - encode new icon to tool types text datas
            var textDatas = NewIconToolTypesEncoder.Encode(imageNumber, newIcon).ToList();

            // act - create decoder to decode tool types text datas
            var decoder = new NewIconToolTypesDecoder(textDatas);
            
            // act - decode tool types text datas to new icon
            var decodedNewIcon = decoder.Decode(imageNumber);

            // assert - new icon and decoded new icon width, height, depth and transparency are equal
            Assert.Equal(newIcon.Width, decodedNewIcon.Width);
            Assert.Equal(newIcon.Height, decodedNewIcon.Height);
            Assert.Equal(newIcon.Depth, decodedNewIcon.Depth);
            Assert.Equal(newIcon.Transparent, decodedNewIcon.Transparent);

            // assert - new icon and decoded new icon are equal
            Assert.Equal(newIcon.Palette.Length, decodedNewIcon.Palette.Length);
            for (var i = 0; i < newIcon.Palette.Length; i++)
            {
                Assert.Equal(newIcon.Palette[i][0], decodedNewIcon.Palette[i][0]);
                Assert.Equal(newIcon.Palette[i][1], decodedNewIcon.Palette[i][1]);
                Assert.Equal(newIcon.Palette[i][2], decodedNewIcon.Palette[i][2]);
            }

            // assert - new icon and decoded new icon image pixels are equal
            Assert.Equal(newIcon.ImagePixels.Length, decodedNewIcon.ImagePixels.Length);
            for (var i = 0; i < newIcon.ImagePixels.Length; i++)
            {
                Assert.Equal(newIcon.ImagePixels[i], decodedNewIcon.ImagePixels[i]);
            }
            
            // assert - decoded new icon is equal to image
            AssertEqual(image, decodedNewIcon);
        }
    }
}