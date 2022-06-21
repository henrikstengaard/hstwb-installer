namespace HstWbInstaller.Core.Tests.InfoTests
{
    using System.IO;
    using System.Linq;
    using System.Text;
    using System.Threading.Tasks;
    using IO.Info;
    using Xunit;

    public class GivenNewIconToolTypesEncoder
    {
        [Fact]
        public void WhenEncodeNewIconSized2X2PixelsWith2ColorsThenToolTypesMatchExpectedToolTypes()
        {
            // arrange - create expected text datas
            var expectedTextDatas = NewIconSized2X2PixelsWith2ColorsTestHelper.CreateTextDatas().ToList();

            // act - encode palette, image pixels and get tool types
            var textDatas = NewIconToolTypesEncoder.Encode(
                NewIconSized2X2PixelsWith2ColorsTestHelper.ImageNumber,
                NewIconSized2X2PixelsWith2ColorsTestHelper.NewIcon).ToList();

            // assert - text datas are equal 
            Assert.Equal(expectedTextDatas.Count, textDatas.Count);
            for (var i = 0; i < expectedTextDatas.Count; i++)
            {
                Assert.Equal(expectedTextDatas[i].Size, textDatas[i].Size);
                Assert.Equal(expectedTextDatas[i].Data, textDatas[i].Data);
            }
        }
        
        [Fact]
        public async Task WhenEncodeNewIconToToolTypesThenToolTypesMatchIConverterCreatedToolTypes()
        {
            // arrange - image number and new icon
            const int imageNumber = 1;
            var newIcon = new NewIcon
            {
                Width = 8,
                Height = 8,
                Depth = 2, // 4 colors (math.pow(2, 2))
                Palette = new[]
                {
                    new byte[] { 170, 170, 170, 255 },
                    new byte[] { 0, 0, 0, 255 },
                    new byte[] { 255, 255, 255, 255 },
                    new byte[] { 102, 136, 187, 255 },
                },
                ImagePixels = new byte[]
                {
                    0, 0, 0, 0, 1, 1, 1, 1,
                    0, 0, 0, 0, 1, 1, 1, 1,
                    0, 0, 0, 0, 1, 1, 1, 1,
                    0, 0, 0, 0, 1, 1, 1, 1,
                    2, 2, 2, 2, 3, 3, 3, 3,
                    2, 2, 2, 2, 3, 3, 3, 3,
                    2, 2, 2, 2, 3, 3, 3, 3,
                    2, 2, 2, 2, 3, 3, 3, 3
                }
            };

            // arrange - load iconverter created newicon info
            await using var stream = File.OpenRead(@"TestData\Info\Drawer-NewIcon-IConverter.info");
            var diskObject = await DiskObjectReader.Read(stream);

            // arrange - get image number 1 tool types
            var expectedToolTypes =
                diskObject.ToolTypes.TextDatas.Where(
                    x => x.Size >= 4 && Encoding.ASCII.GetString(x.Data, 0, 4) == $"IM{imageNumber}=").ToList();

            // act - encode new icon to tool types
            var toolTypes = NewIconToolTypesEncoder.Encode(imageNumber, newIcon).ToList();
            
            // assert - encoded tool types are equal to iconverter tool types 
            Assert.Equal(expectedToolTypes.Count, toolTypes.Count);
            for (var i = 0; i < expectedToolTypes.Count; i++)
            {
                Assert.Equal(expectedToolTypes[i].Size, toolTypes[i].Size);
                Assert.Equal(expectedToolTypes[i].Data, toolTypes[i].Data);
            }
        }
    }
}