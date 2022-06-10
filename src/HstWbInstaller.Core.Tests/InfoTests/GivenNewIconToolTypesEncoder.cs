namespace HstWbInstaller.Core.Tests.InfoTests
{
    using System.IO;
    using System.Linq;
    using System.Text;
    using System.Threading.Tasks;
    using IO.Info;
    using SixLabors.ImageSharp;
    using SixLabors.ImageSharp.Formats.Png;
    using SixLabors.ImageSharp.PixelFormats;
    using Xunit;

    public class GivenNewIconToolTypesEncoder
    {
        [Fact]
        public async Task WhenEncodeImagePixelsThenToolTypesMatchIConverterCreatedToolTypes2()
        {
            // arrange - image number, dimension and depth
            const int imageNumber = 1;
            const int width = 8;
            const int height = 8;
            const int depth = 2; // 4 colors (math.pow(2, 2))

            // arrange - palette
            var palette = new[]
            {
                new byte[] { 170, 170, 170, 255 },
                new byte[] { 0, 0, 0, 255 },
                new byte[] { 255, 255, 255, 255 },
                new byte[] { 102, 136, 187, 255 },
            };

            // arrange - image pixels 
            var imagePixels = new byte[]
            {
                0, 0, 0, 0, 1, 1, 1, 1,
                0, 0, 0, 0, 1, 1, 1, 1,
                0, 0, 0, 0, 1, 1, 1, 1,
                0, 0, 0, 0, 1, 1, 1, 1,
                2, 2, 2, 2, 3, 3, 3, 3,
                2, 2, 2, 2, 3, 3, 3, 3,
                2, 2, 2, 2, 3, 3, 3, 3,
                2, 2, 2, 2, 3, 3, 3, 3
            };

            // arrange - load iconverter created newicon info
            await using var stream = File.OpenRead(@"TestData\Info\Drawer-NewIcon.info");
            var diskObject = await DiskObjectReader.Read(stream);

            // arrange - get im1 tooltypes
            var expectedToolTypes =
                diskObject.ToolTypes.TextDatas.Where(
                    x => x.Size >= 4 && Encoding.ASCII.GetString(x.Data, 0, 4) == "IM1=").ToList();

            // act - encode palette, image pixels and get tool types
            var encoder = new NewIconToolTypesEncoder(imageNumber, width, height, depth, false);
            encoder.EncodePalette(palette);
            encoder.EncodeImage(imagePixels);
            var toolTypes = encoder.GetToolTypes().ToList();

            // assert - tool types are equal 
            Assert.Equal(expectedToolTypes.Count, toolTypes.Count);
            for (var i = 0; i < expectedToolTypes.Count; i++)
            {
                Assert.Equal(expectedToolTypes[i].Size, toolTypes[i].Size);
                Assert.Equal(expectedToolTypes[i].Data, toolTypes[i].Data);
            }
        }

        [Fact]
        public async Task WhenEncodeImagePixelsFromPngThenToolTypesMatch()
        {
            // arrange - paths
            var firstImagePath = @"TestData\Info\flashback-image1.png";
            var secondImagePath = @"TestData\Info\bubble_bobble2.png";

            // arrange - read first and second images
            var firstImage = await Image.LoadAsync<Rgba32>(File.OpenRead(firstImagePath), new PngDecoder());
            var secondImage = await Image.LoadAsync<Rgba32>(File.OpenRead(secondImagePath), new PngDecoder());

            // arrange - encode new icon image
            var firstNewIcon = NewIconEncoder.Encode(firstImage);
            var secondNewIcon = NewIconEncoder.Encode(secondImage);

            // act - encode palette, image pixels and get tool types
            // var firstNewIconEncoder = new NewIconToolTypesEncoder(1, firstNewIcon.Width, firstNewIcon.Height,
            //     firstNewIcon.Depth, firstNewIcon.Transparent);
            // firstNewIconEncoder.EncodePalette(firstNewIcon.Palette);
            // firstNewIconEncoder.EncodeImage(firstNewIcon.ImagePixels);
            // var firstNewIconToolTypes = firstNewIconEncoder.GetToolTypes().ToList();

            // var image1TextDatas =
            //     diskObject.ToolTypes.TextDatas.Where(x =>
            //             x.Size >= 4 && Encoding.ASCII.GetString(x.Data, 0, 4) == $"IM1=")
            //         .ToList();
            //
            var defaultImage = TestDataHelper.CreateFirstImage();

            var newDiskObject = InfoHelper.CreateProjectInfo();
            InfoHelper.SetFirstImage(newDiskObject, TestDataHelper.Palette, defaultImage, TestDataHelper.Depth);
            // InfoHelper.SetSecondImage(newDiskObject, TestDataHelper.Palette, defaultImage, TestDataHelper.Depth);
            NewIconHelper.SetNewIconImage(newDiskObject, 1, secondNewIcon);
            //NewIconHelper.SetNewIconImage(newDiskObject, 2, secondNewIcon);

            await using var newStream = File.Open("bubble_bobble.info", FileMode.Create);
            await DiskObjectWriter.Write(newDiskObject, newStream);

            //newDiskObject.Gadget.

            // assert - tool types are equal 
            // Assert.Equal(expectedToolTypes.Count, toolTypes.Count);
            // for (var i = 0; i < expectedToolTypes.Count; i++)
            // {
            //     Assert.Equal(expectedToolTypes[i].Size, toolTypes[i].Size);
            //     Assert.Equal(expectedToolTypes[i].Data, toolTypes[i].Data);
            // }
        }
    }
}