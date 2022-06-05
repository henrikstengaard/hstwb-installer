namespace HstWbInstaller.Core.Tests.InfoTests
{
    using System.IO;
    using System.Threading.Tasks;
    using IO.Info;
    using SixLabors.ImageSharp;
    using SixLabors.ImageSharp.PixelFormats;
    using Xunit;

    public class GivenInfoHelper
    {
        [Fact]
        public async Task WhenCreatingDiskInfoThenDiskObjectMatchesDisk()
        {
            // arrange - create first and second images
            var firstImage = TestDataHelper.CreateFirstImage();
            var secondImage = TestDataHelper.CreateSecondImage();

            // act - create disk info disk object
            var diskObject =
                InfoHelper.CreateDiskInfo();
            InfoHelper.SetFirstImage(diskObject, TestDataHelper.Palette, firstImage, TestDataHelper.Depth);
            InfoHelper.SetSecondImage(diskObject, TestDataHelper.Palette, secondImage, TestDataHelper.Depth);

            // act - write disk object for manual testing
            await using var stream = File.Open("disk.info", FileMode.Create);
            await DiskObjectWriter.Write(diskObject, stream);
            
            // assert - disk object is a disk
            Assert.Equal(Constants.DiskObjectTypes.DISK, diskObject.Type);
            Assert.Equal(33559167U, diskObject.DrawerData.Flags);

            // assert - first and second images are equal
            AssertImages(firstImage, secondImage, diskObject);
            
            // assert - disk object has default values
            AssertDefaultValues(diskObject);
        }
        
        [Fact]
        public async Task WhenCreatingDrawerInfoThenDiskObjectMatchesDrawer()
        {
            // arrange - create first and second images
            var firstImage = TestDataHelper.CreateFirstImage();
            var secondImage = TestDataHelper.CreateSecondImage();

            // act - create disk info drawer object
            var diskObject =
                InfoHelper.CreateDrawerInfo();
            InfoHelper.SetFirstImage(diskObject, TestDataHelper.Palette, firstImage, TestDataHelper.Depth);
            InfoHelper.SetSecondImage(diskObject, TestDataHelper.Palette, secondImage, TestDataHelper.Depth);

            // act - write disk object for manual testing
            await using var stream = File.Open("drawer.info", FileMode.Create);
            await DiskObjectWriter.Write(diskObject, stream);
            
            // assert - disk object is a drawer
            Assert.Equal(Constants.DiskObjectTypes.DRAWER, diskObject.Type);
            Assert.Equal(33559103U, diskObject.DrawerData.Flags);

            // assert - first and second images are equal
            AssertImages(firstImage, secondImage, diskObject);
            
            // assert - disk object has default values
            AssertDefaultValues(diskObject);
        }
        
        [Fact]
        public async Task WhenCreatingProjectInfoThenDiskObjectMatchesProject()
        {
            // arrange - create first and second images
            var firstImage = TestDataHelper.CreateFirstImage();
            var secondImage = TestDataHelper.CreateSecondImage();

            // act - create disk info project object
            var diskObject =
                InfoHelper.CreateProjectInfo();
            InfoHelper.SetFirstImage(diskObject, TestDataHelper.Palette, firstImage, TestDataHelper.Depth);
            InfoHelper.SetSecondImage(diskObject, TestDataHelper.Palette, secondImage, TestDataHelper.Depth);

            // act - write disk object for manual testing
            await using var stream = File.Open("project.info", FileMode.Create);
            await DiskObjectWriter.Write(diskObject, stream);
            
            // assert - disk object is a project
            Assert.Equal(Constants.DiskObjectTypes.PROJECT, diskObject.Type);

            // assert - first and second images are equal
            AssertImages(firstImage, secondImage, diskObject);
            
            // assert - disk object has default values
            AssertDefaultValues(diskObject);
        }
        
        private static void AssertImages(Image<Rgba32> firstImage, Image<Rgba32> secondImage, DiskObject diskObject)
        {
            // assert - first image data is equal to first image
            Assert.NotNull(diskObject.FirstImageData);
            Assert.Equal(firstImage.Width, diskObject.FirstImageData.Width);
            Assert.Equal(firstImage.Height, diskObject.FirstImageData.Height);
            Assert.Equal(2, diskObject.FirstImageData.Depth);

            // assert - second image data is equal to second image
            Assert.NotNull(diskObject.SecondImageData);
            Assert.Equal(secondImage.Width, diskObject.SecondImageData.Width);
            Assert.Equal(secondImage.Height, diskObject.SecondImageData.Height);
            Assert.Equal(2, diskObject.SecondImageData.Depth);
            
            // assert - first image size is equal to gadget size 
            Assert.Equal(firstImage.Width, diskObject.Gadget.Width);
            Assert.Equal(firstImage.Height, diskObject.Gadget.Height);

            // assert - gadget render pointer is set, indicates first image is present
            Assert.NotEqual(0U, diskObject.Gadget.GadgetRenderPointer);
            
            // assert - second image size is equal to gadget size 
            Assert.Equal(secondImage.Width, diskObject.Gadget.Width);
            Assert.Equal(secondImage.Height, diskObject.Gadget.Height);

            // assert - select render pointer is set, indicates second image is present
            Assert.NotEqual(0U, diskObject.Gadget.SelectRenderPointer);
        }

        private static void AssertDefaultValues(DiskObject diskObject)
        {
            // assert - disk object has default values
            Assert.Equal(4096, diskObject.StackSize);
            Assert.Equal(0U, diskObject.DefaultToolPointer);
            Assert.Null(diskObject.DefaultTool);
            Assert.Equal(0U, diskObject.ToolTypesPointer);
            Assert.Null(diskObject.ToolTypes);
            
            // assert - gadget has default values
            Assert.Equal(1, diskObject.Gadget.Activation);
            Assert.Equal(6, diskObject.Gadget.Flags);

            if (diskObject.Type != Constants.DiskObjectTypes.DISK &&
                diskObject.Type != Constants.DiskObjectTypes.DRAWER) return;
            
            // assert - drawer data has default values
            Assert.Equal(0U, diskObject.DrawerData.BitMap);
            Assert.Equal(255, diskObject.DrawerData.BlockPen);
            Assert.Equal(0U, diskObject.DrawerData.CheckMark);
            Assert.Equal(255, diskObject.DrawerData.DetailPen);
            Assert.NotEqual(0U, diskObject.DrawerData.FirstGadget);
            Assert.Equal(0U, diskObject.DrawerData.IdcmpFlags);
            Assert.Equal(65535, diskObject.DrawerData.MaxHeight);
            Assert.Equal(65535, diskObject.DrawerData.MaxWidth);
            Assert.Equal(0U, diskObject.DrawerData.Screen);
            Assert.NotEqual(0U, diskObject.DrawerData.Title);
            Assert.Equal(1, diskObject.DrawerData.Type);
        }
    }
}