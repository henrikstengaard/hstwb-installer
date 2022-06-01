namespace HstWbInstaller.Core.Tests.InfoTests
{
    using System.Linq;
    using System.Text;
    using System.Threading.Tasks;
    using IO.Info;
    using Xunit;

    public class GivenNewIconToolTypesEncoder
    {
        [Fact]
        public async Task WhenEncodeImagePixelsThenToolTypesMatchIConverterCreatedToolTypes()
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
            var imagePixels = new[]
            {
                new byte[]{ 0, 0, 0, 0, 1, 1, 1, 1 },
                new byte[]{ 0, 0, 0, 0, 1, 1, 1, 1 },
                new byte[]{ 0, 0, 0, 0, 1, 1, 1, 1 },
                new byte[]{ 0, 0, 0, 0, 1, 1, 1, 1 },
                new byte[]{ 2, 2, 2, 2, 3, 3, 3, 3 },
                new byte[]{ 2, 2, 2, 2, 3, 3, 3, 3 },
                new byte[]{ 2, 2, 2, 2, 3, 3, 3, 3 },
                new byte[]{ 2, 2, 2, 2, 3, 3, 3, 3 }
            };
            
            // arrange - load iconverter created newicon info
            await using var stream = System.IO.File.OpenRead(@"TestData\Info\Drawer-NewIcon.info");
            var diskObject = await DiskObjectReader.Read(stream);
            
            // arrange - get im1 tooltypes
            var expectedToolTypes =
                diskObject.ToolTypes.TextDatas.Where(
                    x => x.Size >= 4 && Encoding.ASCII.GetString(x.Data, 0, 4) == "IM1=").ToList();
            
            // act - encode palette, image pixels and get tool types
            var encoder = new NewIconsToolTypesEncoder(imageNumber, width, height, depth, false);
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
    }
}