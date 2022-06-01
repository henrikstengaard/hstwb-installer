namespace HstWbInstaller.Core.Tests.InfoTests
{
    using System.IO;
    using System.Threading.Tasks;
    using IO.Info;
    using SixLabors.ImageSharp;
    using SixLabors.ImageSharp.Formats.Png;
    using SixLabors.ImageSharp.PixelFormats;
    using Xunit;

    public class GivenNewIconToolTypesDecoder : InfoTestBase
    {
        [Fact]
        public async Task WhenDecodingNewIconForFirstImageThenImageMatches()
        {
            // arrange - paths
            var newIconPath = @"TestData\Info\Flashback.newicon";
            var expectedNewIconImagePath = @"TestData\Info\Flashback-image1.png";
            var imageNumber = 1;

            // arrange - read expected image
            await using var imageStream = File.OpenRead(expectedNewIconImagePath);
            var expectedImage = await Image.LoadAsync<Rgba32>(imageStream, new PngDecoder());

            // arrange - read disk object with new icon
            var diskObject = await DiskObjectReader.Read(File.OpenRead(newIconPath));

            // act - create new icon tool types decoder
            var decoder = new NewIconToolTypesDecoder(diskObject.ToolTypes.TextDatas);

            // act - decode image number 1
            var newIcon = decoder.Decode(imageNumber);

            // assert - new icon image is equal to expected image
            var image = NewIconHelper.ConvertToImage(newIcon);
            AssertEqual(expectedImage, image);
        }

        [Fact]
        public async Task WhenDecodingNewIconForSecondImageThenImageMatches()
        {
            // arrange - paths
            var newIconPath = @"TestData\Info\Flashback.newicon";
            var expectedNewIconImagePath = @"TestData\Info\Flashback-image2.png";
            var imageNumber = 2;

            // arrange - read expected image
            await using var imageStream = File.OpenRead(expectedNewIconImagePath);
            var expectedImage = await Image.LoadAsync<Rgba32>(imageStream, new PngDecoder());

            // arrange - read disk object with new icon
            var diskObject = await DiskObjectReader.Read(File.OpenRead(newIconPath));

            // act - create new icon tool types decoder
            var decoder = new NewIconToolTypesDecoder(diskObject.ToolTypes.TextDatas);

            // act - decode image number 2
            var newIcon = decoder.Decode(imageNumber);

            // assert - new icon image is equal to expected image
            var image = NewIconHelper.ConvertToImage(newIcon);
            AssertEqual(expectedImage, image);
        }
    }
}