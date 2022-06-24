namespace HstWbInstaller.Core.Tests.InfoTests
{
    using System.IO;
    using System.Threading.Tasks;
    using ImageTests;
    using IO.Info;
    using SixLabors.ImageSharp.Formats.Png;
    using SixLabors.ImageSharp.PixelFormats;
    using Xunit;
    using Image = SixLabors.ImageSharp.Image;

    public class GivenColorIconReader
    {
        [Fact]
        public async Task WhenReadColorIconThenImagesMatch()
        {
            // arrange - read expected first and second image
            var expectedFirstImagePath = @"TestData\ColorIcons\AF-OS35-Icons1-image1.png";
            var expectedFirstImage = await Image.LoadAsync<Rgba32>(File.OpenRead(expectedFirstImagePath), new PngDecoder());
            var expectedSecondImagePath = @"TestData\ColorIcons\AF-OS35-Icons1-image2.png";
            var expectedSecondImage = await Image.LoadAsync<Rgba32>(File.OpenRead(expectedSecondImagePath), new PngDecoder());

            // act - read color icon
            await using var stream = File.OpenRead(@"TestData\ColorIcons\AF-OS35-Icons1.readme.info");
            var colorIcon = await ColorIconReader.Read(stream);

            // assert - image pixels matches
            var firstImage = ColorIconConverter.ToImage(colorIcon.Images[0]);
            var secondImage = ColorIconConverter.ToImage(colorIcon.Images[1]);
            ImageTestHelper.AssertEqual(expectedFirstImage, firstImage);
            ImageTestHelper.AssertEqual(expectedSecondImage, secondImage);
        }
    }
}