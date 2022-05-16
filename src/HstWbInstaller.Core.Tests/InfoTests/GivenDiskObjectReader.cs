namespace HstWbInstaller.Core.Tests.InfoTests
{
    using System.IO;
    using System.Threading.Tasks;
    using IO.Info;
    using SixLabors.ImageSharp;
    using Xunit;

    public class GivenDiskObjectReader
    {
        [Fact]
        public async Task WhenReadDiskObjectFromDiskInfoFileThenDiskObjectIsValid()
        {
            var path = @"TestData\Info\Disk.info";
            var diskObject = await DiskObjectReader.Read(File.OpenRead(path));
            
            Assert.Equal(Constants.DiskObjectTypes.DISK, diskObject.Type);
            Assert.Equal(55, diskObject.Gadget.Width);
            Assert.Equal(23, diskObject.Gadget.Height);

            var image1 = ImageDataConverter.ConvertToImage(diskObject.FirstImageData, AmigaOs31Palette.FullPalette);
            await image1.SaveAsPngAsync("icon1.png");

            var image2 = ImageDataConverter.ConvertToImage(diskObject.SecondImageData, AmigaOs31Palette.FullPalette);
            await image2.SaveAsPngAsync("icon2.png");
        }
        
        [Fact]
        public async Task WhenReadDiskObjectFromProjectInfoFileThenDiskObjectIsValid()
        {
            var path = @"TestData\Info\iGame.info";
            var diskObject = await DiskObjectReader.Read(File.OpenRead(path));
            
            Assert.Equal(Constants.DiskObjectTypes.TOOL, diskObject.Type);
            Assert.Equal(55, diskObject.Gadget.Width);
            Assert.Equal(23, diskObject.Gadget.Height);

            var image1 = ImageDataConverter.ConvertToImage(diskObject.FirstImageData, AmigaOs31Palette.FullPalette);
            await image1.SaveAsPngAsync("icon1.png");

            var image2 = ImageDataConverter.ConvertToImage(diskObject.SecondImageData, AmigaOs31Palette.FullPalette);
            await image2.SaveAsPngAsync("icon2.png");
        }
    }
}