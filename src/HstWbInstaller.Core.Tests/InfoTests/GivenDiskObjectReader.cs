namespace HstWbInstaller.Core.Tests.InfoTests
{
    using System.IO;
    using System.Linq;
    using System.Text;
    using System.Threading.Tasks;
    using IO.Info;
    using Xunit;
    using Constants = IO.Info.Constants;

    public class GivenDiskObjectReader
    {
        [Fact]
        public async Task WhenReadDiskObjectFromDiskInfoFileThenDiskObjectMatchesDisk()
        {
            // arrange - path to disk info
            var path = @"TestData\Info\Disk.info";
            
            // act - read disk object from disk info
            var diskObject = await DiskObjectReader.Read(File.OpenRead(path));
            
            // assert - disk object is a disk
            Assert.Equal(Constants.DiskObjectTypes.DISK, diskObject.Type);
            Assert.Equal(55, diskObject.Gadget.Width);
            Assert.Equal(23, diskObject.Gadget.Height);
            Assert.Equal(1, diskObject.Gadget.Activation);
            Assert.Equal(6, diskObject.Gadget.Flags);

            // assert - first image is present, gadget render pointer is set
            Assert.NotEqual(0U, diskObject.Gadget.GadgetRenderPointer);
            
            // assert - first image is equal to gadget
            Assert.NotNull(diskObject.FirstImageData);
            Assert.Equal(55, diskObject.FirstImageData.Width);
            Assert.Equal(23, diskObject.FirstImageData.Height);
            Assert.Equal(3, diskObject.FirstImageData.Depth); // 8 colors, bits 4, 2, 1

            // assert - second image is present, select render pointer is set
            Assert.NotEqual(0U, diskObject.Gadget.SelectRenderPointer);
            
            // assert - second image is equal to gadget
            Assert.NotNull(diskObject.SecondImageData);
            Assert.Equal(55, diskObject.SecondImageData.Width);
            Assert.Equal(23, diskObject.SecondImageData.Height);
            Assert.Equal(3, diskObject.SecondImageData.Depth); // 8 colors, bits 4, 2, 1

            // assert - drawer data is present, drawer data pointer is set
            Assert.NotEqual(0U, diskObject.DrawerDataPointer);

            // assert - drawer data is equal to disk info
            Assert.NotNull(diskObject.DrawerData);
            Assert.Equal(33559103U, diskObject.DrawerData.Flags);
        }

        [Fact]
        public async Task WhenReadDiskObjectFromDrawerInfoFileThenDiskObjectMatchesDrawer()
        {
            // arrange - path to drawer info
            var path = @"TestData\Info\Drawer.info";
            
            // act - read disk object from disk info
            var diskObject = await DiskObjectReader.Read(File.OpenRead(path));
            
            // assert - disk object is a drawer
            Assert.Equal(Constants.DiskObjectTypes.DRAWER, diskObject.Type);
            Assert.Equal(56, diskObject.Gadget.Width);
            Assert.Equal(15, diskObject.Gadget.Height);
            Assert.Equal(1, diskObject.Gadget.Activation);
            Assert.Equal(6, diskObject.Gadget.Flags);

            // assert - first image is present, gadget render pointer is set
            Assert.NotEqual(0U, diskObject.Gadget.GadgetRenderPointer);
            
            // assert - first image is equal to gadget
            Assert.NotNull(diskObject.FirstImageData);
            Assert.Equal(56, diskObject.FirstImageData.Width);
            Assert.Equal(15, diskObject.FirstImageData.Height);
            Assert.Equal(3, diskObject.FirstImageData.Depth); // 8 colors, bits 4, 2, 1
            
            // assert - second image is present, select render pointer is set
            Assert.NotEqual(0U, diskObject.Gadget.SelectRenderPointer);
            
            // assert - second image is equal to gadget
            Assert.NotNull(diskObject.SecondImageData);
            Assert.Equal(56, diskObject.SecondImageData.Width);
            Assert.Equal(15, diskObject.SecondImageData.Height);
            Assert.Equal(3, diskObject.SecondImageData.Depth); // 8 colors, bits 4, 2, 1

            // assert - drawer data is present, drawer data pointer is set
            Assert.NotEqual(0U, diskObject.DrawerDataPointer);

            // assert - drawer data is equal to drawer info
            Assert.NotNull(diskObject.DrawerData);
            Assert.Equal(33559103U, diskObject.DrawerData.Flags);
        }
        
        [Fact]
        public async Task WhenReadDiskObjectFromToolInfoFileThenDiskObjectMatchesTool()
        {
            var path = @"TestData\Info\iGame.info";
            var diskObject = await DiskObjectReader.Read(File.OpenRead(path));

            // assert - disk object is a tool type
            Assert.Equal(Constants.DiskObjectTypes.TOOL, diskObject.Type);
            Assert.Equal(55, diskObject.Gadget.Width);
            Assert.Equal(23, diskObject.Gadget.Height);
            Assert.Equal(1, diskObject.Gadget.Activation);
            Assert.Equal(6, diskObject.Gadget.Flags);

            // assert - first image is present, gadget render pointer is set
            Assert.NotEqual(0U, diskObject.Gadget.GadgetRenderPointer);
            
            // assert - first image is equal to gadget
            Assert.NotNull(diskObject.FirstImageData);
            Assert.Equal(55, diskObject.FirstImageData.Width);
            Assert.Equal(23, diskObject.FirstImageData.Height);
            Assert.Equal(3, diskObject.FirstImageData.Depth); // 8 colors, bits 4, 2, 1

            // assert - second image is present, select render pointer is set
            Assert.NotEqual(0U, diskObject.Gadget.SelectRenderPointer);
            
            // assert - second image is equal to gadget
            Assert.NotNull(diskObject.SecondImageData);
            Assert.Equal(55, diskObject.SecondImageData.Width);
            Assert.Equal(23, diskObject.SecondImageData.Height);
            Assert.Equal(3, diskObject.SecondImageData.Depth); // 8 colors, bits 4, 2, 1

            // assert - drawer data is not present, drawer data pointer is set to 0
            Assert.Equal(0U, diskObject.DrawerDataPointer);

            // assert - drawer data is null
            Assert.Null(diskObject.DrawerData);
            
            // assert - default tool is null
            Assert.Null(diskObject.DefaultTool);
            
            // assert - tool types tool is present and contains 3 strings
            Assert.NotNull(diskObject.ToolTypes);
            Assert.Equal(3, diskObject.ToolTypes.TextDatas.Count());
            var toolTypesStrings = InfoHelper.ConvertToolTypesToStrings(diskObject.ToolTypes).ToList();
            Assert.Equal("(SCREENSHOT=WIDTHxHEIGHT)", toolTypesStrings[0]);
            Assert.Equal("NOGUIGFX", toolTypesStrings[1]);
            Assert.Equal("(FILTERUSEENTER)", toolTypesStrings[2]);
        }

        [Fact]
        public async Task WhenReadDiskObjectFromInfoWithNewIconThenDiskObjectToolTypesContainNewIcons()
        {
            // arrange - paths
            var newIconPath = @"TestData\Info\Flashback.newicon";

            // act - read disk object with new icon
            var diskObject = await DiskObjectReader.Read(File.OpenRead(newIconPath));

            // assert - disk object contains image number 1 text datas
            var image1TextDatas =
                diskObject.ToolTypes.TextDatas.Where(x =>
                        x.Size >= 4 && Encoding.ASCII.GetString(x.Data, 0, 4) == $"IM1=")
                    .ToList();
            Assert.NotEmpty(image1TextDatas);
            
            // assert - disk object contains image number 2 text datas
            var image2TextDatas =
                diskObject.ToolTypes.TextDatas.Where(x =>
                        x.Size >= 4 && Encoding.ASCII.GetString(x.Data, 0, 4) == $"IM2=")
                    .ToList();
            Assert.NotEmpty(image2TextDatas);
        }
    }
}