namespace HstWbInstaller.Core.Tests.InfoTests
{
    using System.Collections.Generic;
    using System.IO;
    using System.Linq;
    using System.Threading.Tasks;
    using IO.Info;
    using IO.Info.Errors;
    using SixLabors.ImageSharp;
    using SixLabors.ImageSharp.Formats.Png;
    using SixLabors.ImageSharp.PixelFormats;
    using Xunit;

    public class GivenNewIconHelper
    {
        [Fact]
        public void WhenSettingFirstNewIconImageThenTextDatasAreAddedToToolTypes()
        {
            var imageNumber = 1;
            var newIcon = NewIconSized2X2PixelsWith2ColorsTestHelper.NewIcon;

            var diskObject = InfoHelper.CreateDiskInfo();
            NewIconHelper.SetNewIconImage(diskObject, imageNumber, newIcon);

            var textDatas = diskObject.ToolTypes.TextDatas.ToList();
            Assert.NotEmpty(textDatas);

            // assert - first text data contains a space and zero to terminate text data
            var newIconSpaceTextData = new byte[] { 32, 0 };
            Assert.Equal(newIconSpaceTextData.Length, textDatas[0].Data.Length);
            Assert.Equal(newIconSpaceTextData, textDatas[0].Data);

            // assert - second text data contains new icon header (don't edit the following lines)
            var newIconHeaderTextData =
                AmigaTextHelper.GetBytes(Constants.NewIcon.Header).Concat(new byte[] { 0 }).ToArray();
            Assert.Equal(newIconHeaderTextData.Length, textDatas[1].Data.Length);
            Assert.Equal(newIconHeaderTextData, textDatas[1].Data);

            // assert - remaining text datas contain image 1 text datas
            var imageHeader = $"IM{imageNumber}=";
            var image1TextDatas = textDatas.Skip(2).Where(x =>
                x.Data.Length >= 4 && AmigaTextHelper.GetString(x.Data, 0, 4).Equals(imageHeader)).ToList();
            Assert.Equal(textDatas.Count - 2, image1TextDatas.Count);
        }

        [Fact]
        public void WhenSettingFirstAndSecondNewIconImageThenTextDatasAreAddedToToolTypes()
        {
            const int firstImageNumber = 1;
            const int secondImageNumber = 2;
            var newIcon = NewIconSized2X2PixelsWith2ColorsTestHelper.NewIcon;

            var diskObject = InfoHelper.CreateDiskInfo();
            NewIconHelper.SetNewIconImage(diskObject, firstImageNumber, newIcon);
            NewIconHelper.SetNewIconImage(diskObject, secondImageNumber, newIcon);

            var textDatas = diskObject.ToolTypes.TextDatas.ToList();
            Assert.NotEmpty(textDatas);

            AssertNewIconSpaceAndHeaderExist(textDatas);

            // assert - find next text data offset not matching first image header
            var firstImageHeader = $"IM{firstImageNumber}=";
            var textDataOffset = 2;
            for (;
                 textDataOffset < textDatas.Count &&
                 textDatas[textDataOffset].Data.Length >= 4 &&
                 AmigaTextHelper.GetString(textDatas[textDataOffset].Data, 0, 4).Equals(firstImageHeader);
                 textDataOffset++)
            {
            }

            // assert - last found text data offset for first new icon image is greater than 2
            Assert.True(textDataOffset > 2);

            var secondImageStartTextDataOffset = textDataOffset;

            // assert - find next text data offset not matching second image header
            var secondImageHeader = $"IM{secondImageNumber}=";
            for (;
                 textDataOffset < textDatas.Count &&
                 textDatas[textDataOffset].Data.Length >= 4 &&
                 AmigaTextHelper.GetString(textDatas[textDataOffset].Data, 0, 4).Equals(secondImageHeader);
                 textDataOffset++)
            {
            }

            // assert - last found text data offset for second new icon image is greater than 2
            Assert.True(textDataOffset > secondImageStartTextDataOffset);

            // assert - last found text data offset for second new icon image is equal to last text data
            Assert.Equal(textDatas.Count - 1, textDataOffset - 1);
        }

        [Fact]
        public async Task WhenCreatingNewIconDiskObjectThenValidateNewIconReturnsSuccess()
        {
            var firstImageNumber = 1;
            var firstImagePath = @"TestData\Info\bubble_bobble1.png";
            var secondImageNumber = 2;
            var secondImagePath = @"TestData\Info\bubble_bobble2.png";

            // arrange - read first and second images
            var firstImage = await Image.LoadAsync<Rgba32>(File.OpenRead(firstImagePath), new PngDecoder());
            var secondImage = await Image.LoadAsync<Rgba32>(File.OpenRead(secondImagePath), new PngDecoder());

            // arrange - encode first and second images to new icon images
            var firstNewIcon = NewIconEncoder.Encode(firstImage);
            var secondNewIcon = NewIconEncoder.Encode(secondImage);

            // arrange - create dummy planar icon
            var defaultImage = TestDataHelper.CreateFirstImage();

            // arrange - create new project disk object icon
            var floppyDiskObject = InfoHelper.CreateProjectInfo();

            // arrange - set normal/first image
            InfoHelper.SetFirstImage(floppyDiskObject, TestDataHelper.Palette, defaultImage, TestDataHelper.Depth);

            // arrange - set first and second new icon images
            NewIconHelper.SetNewIconImage(floppyDiskObject, firstImageNumber, firstNewIcon);
            NewIconHelper.SetNewIconImage(floppyDiskObject, secondImageNumber, secondNewIcon);

            // act - validate new icon
            var result = NewIconHelper.ValidateNewIcon(floppyDiskObject);
            var hasValidNewIcon = NewIconHelper.HasValidNewIcon(floppyDiskObject);

            // assert - validate new icon returned success and no error
            Assert.True(hasValidNewIcon);
            Assert.True(result.IsSuccess);
            Assert.False(result.IsFaulted);
            Assert.Null(result.Error);
        }

        [Fact]
        public async Task WhenCreatingNewIconDiskObjectWithoutNormalPlanarImageThenValidateNewIconReturnsError()
        {
            var firstImageNumber = 1;
            var firstImagePath = @"TestData\Info\bubble_bobble1.png";
            var secondImageNumber = 2;
            var secondImagePath = @"TestData\Info\bubble_bobble2.png";

            // arrange - read first and second images
            var firstImage = await Image.LoadAsync<Rgba32>(File.OpenRead(firstImagePath), new PngDecoder());
            var secondImage = await Image.LoadAsync<Rgba32>(File.OpenRead(secondImagePath), new PngDecoder());

            // arrange - encode first and second images to new icon images
            var firstNewIcon = NewIconEncoder.Encode(firstImage);
            var secondNewIcon = NewIconEncoder.Encode(secondImage);

            // arrange - create new project disk object icon
            var floppyDiskObject = InfoHelper.CreateProjectInfo();

            // arrange - set first and second new icon images
            NewIconHelper.SetNewIconImage(floppyDiskObject, firstImageNumber, firstNewIcon);
            NewIconHelper.SetNewIconImage(floppyDiskObject, secondImageNumber, secondNewIcon);

            // act - validate new icon
            var result = NewIconHelper.ValidateNewIcon(floppyDiskObject);
            var hasValidNewIcon = NewIconHelper.HasValidNewIcon(floppyDiskObject);

            // assert - validate new icon returned failed and error
            Assert.False(hasValidNewIcon);
            Assert.False(result.IsSuccess);
            Assert.True(result.IsFaulted);
            Assert.NotNull(result.Error);
            Assert.Equal(typeof(NormalPlanarImageIsNotSetError), result.Error.GetType());
        }

        [Fact]
        public async Task WhenCreatingNewIconDiskObjectWithoutFirstImageThenValidateNewIconReturnsError()
        {
            var secondImageNumber = 2;
            var secondImagePath = @"TestData\Info\bubble_bobble2.png";

            // arrange - read second image
            var secondImage = await Image.LoadAsync<Rgba32>(File.OpenRead(secondImagePath), new PngDecoder());

            // arrange - encode second image to new icon image
            var secondNewIcon = NewIconEncoder.Encode(secondImage);

            // arrange - create dummy planar icon
            var defaultImage = TestDataHelper.CreateFirstImage();

            // arrange - create new project disk object icon
            var floppyDiskObject = InfoHelper.CreateProjectInfo();

            // arrange - set second new icon image
            NewIconHelper.SetNewIconImage(floppyDiskObject, secondImageNumber, secondNewIcon);

            // arrange - set normal/first image
            InfoHelper.SetFirstImage(floppyDiskObject, TestDataHelper.Palette, defaultImage, TestDataHelper.Depth);

            // act - validate new icon
            var result = NewIconHelper.ValidateNewIcon(floppyDiskObject);
            var hasValidNewIcon = NewIconHelper.HasValidNewIcon(floppyDiskObject);

            // assert - validate new icon returned failed and error
            Assert.False(hasValidNewIcon);
            Assert.False(result.IsSuccess);
            Assert.True(result.IsFaulted);
            Assert.NotNull(result.Error);
            Assert.Equal(typeof(NewIconImage1ToolTypesNotPresentError), result.Error.GetType());
        }

        [Fact]
        public void WhenCreatingNewIconDiskObjectWithoutNewIconHeaderThenValidateNewIconReturnsError()
        {
            // arrange - create dummy planar icon
            var defaultImage = TestDataHelper.CreateFirstImage();

            // arrange - create new project disk object icon
            var floppyDiskObject = InfoHelper.CreateProjectInfo();

            // arrange - set normal/first image
            InfoHelper.SetFirstImage(floppyDiskObject, TestDataHelper.Palette, defaultImage, TestDataHelper.Depth);

            // act - validate new icon
            var result = NewIconHelper.ValidateNewIcon(floppyDiskObject);
            var hasValidNewIcon = NewIconHelper.HasValidNewIcon(floppyDiskObject);

            // assert - validate new icon returned failed and error
            Assert.False(hasValidNewIcon);
            Assert.False(result.IsSuccess);
            Assert.True(result.IsFaulted);
            Assert.NotNull(result.Error);
            Assert.Equal(typeof(NewIconHeaderIsNotPresentError), result.Error.GetType());
        }

        [Fact]
        public void WhenCreatingNewIconDiskObjectWithoutNewIconSpaceBeforeHeaderThenValidateNewIconReturnsError()
        {
            // arrange - create dummy planar icon
            var defaultImage = TestDataHelper.CreateFirstImage();

            // arrange - create new project disk object icon
            var diskObject = InfoHelper.CreateProjectInfo();

            // arrange - set normal/first image
            InfoHelper.SetFirstImage(diskObject, TestDataHelper.Palette, defaultImage, TestDataHelper.Depth);

            // arrange - add empty and new icon header text datas
            diskObject.ToolTypes = new ToolTypes
            {
                TextDatas = new[] { InfoHelper.CreateTextData(""), InfoHelper.CreateTextData(Constants.NewIcon.Header) }
            };

            // act - validate new icon
            var result = NewIconHelper.ValidateNewIcon(diskObject);
            var hasValidNewIcon = NewIconHelper.HasValidNewIcon(diskObject);

            // assert - validate new icon returned failed and error
            Assert.False(hasValidNewIcon);
            Assert.False(result.IsSuccess);
            Assert.True(result.IsFaulted);
            Assert.NotNull(result.Error);
            Assert.Equal(typeof(NewIconSpaceIsNotPresentError), result.Error.GetType());
        }

        [Fact]
        public void WhenCreatingNewIconDiskObjectWithNewIconImage2Before1ThenValidateNewIconReturnsError()
        {
            // arrange - create dummy planar icon
            var defaultImage = TestDataHelper.CreateFirstImage();

            // arrange - create new project disk object icon
            var diskObject = InfoHelper.CreateProjectInfo();

            // arrange - set normal/first image
            InfoHelper.SetFirstImage(diskObject, TestDataHelper.Palette, defaultImage, TestDataHelper.Depth);

            // arrange - add new icon space, new icon header, new icon image 1 tool types and only 1 new icon image 2 tool type
            diskObject.ToolTypes = new ToolTypes
            {
                TextDatas = new[]
                    {
                        InfoHelper.CreateTextData(" "), InfoHelper.CreateTextData(Constants.NewIcon.Header),
                    }.Concat(Enumerable.Range(1, 2).Select(_ => InfoHelper.CreateTextData("IM1=")))
                    .Concat(Enumerable.Range(1, 1).Select(_ => InfoHelper.CreateTextData("IM2=")))
                    .Concat(Enumerable.Range(1, 1).Select(_ => InfoHelper.CreateTextData("IM1=")))
            };

            // act - validate new icon
            var result = NewIconHelper.ValidateNewIcon(diskObject);
            var hasValidNewIcon = NewIconHelper.HasValidNewIcon(diskObject);

            // assert - validate new icon returned failed and error
            Assert.False(hasValidNewIcon);
            Assert.False(result.IsSuccess);
            Assert.True(result.IsFaulted);
            Assert.NotNull(result.Error);
            Assert.Equal(typeof(NewIconImage2ToolTypesNotPresentError), result.Error.GetType());
        }

        [Fact]
        public void WhenCreatingNewIconDiskObjectWithOnly1NewIconImage2ToolTypeThenValidateNewIconReturnsError()
        {
            // arrange - create dummy planar icon
            var defaultImage = TestDataHelper.CreateFirstImage();

            // arrange - create new project disk object icon
            var diskObject = InfoHelper.CreateProjectInfo();

            // arrange - set normal/first image
            InfoHelper.SetFirstImage(diskObject, TestDataHelper.Palette, defaultImage, TestDataHelper.Depth);

            // arrange - add new icon space, new icon header, new icon image 1 tool types and only 1 new icon image 2 tool type
            diskObject.ToolTypes = new ToolTypes
            {
                TextDatas = new[]
                    {
                        InfoHelper.CreateTextData(" "), InfoHelper.CreateTextData(Constants.NewIcon.Header),
                    }.Concat(Enumerable.Range(1, 2).Select(_ => InfoHelper.CreateTextData("IM1=")))
                    .Concat(Enumerable.Range(1, 1).Select(_ => InfoHelper.CreateTextData("IM2=")))
            };

            // act - validate new icon
            var result = NewIconHelper.ValidateNewIcon(diskObject);
            var hasValidNewIcon = NewIconHelper.HasValidNewIcon(diskObject);

            // assert - validate new icon returned failed and error
            Assert.False(hasValidNewIcon);
            Assert.False(result.IsSuccess);
            Assert.True(result.IsFaulted);
            Assert.NotNull(result.Error);
            Assert.Equal(typeof(NewIconImage2ToolTypesNotPresentError), result.Error.GetType());
        }
        
        private void AssertNewIconSpaceAndHeaderExist(IList<TextData> textDatas)
        {
            // assert - first text data contains a space and zero to terminate text data
            var newIconSpaceTextData = new byte[] { 32, 0 };
            Assert.Equal(newIconSpaceTextData.Length, textDatas[0].Data.Length);
            Assert.Equal(newIconSpaceTextData, textDatas[0].Data);

            // assert - second text data contains new icon header (don't edit the following lines)
            var newIconHeaderTextData =
                AmigaTextHelper.GetBytes(Constants.NewIcon.Header).Concat(new byte[] { 0 }).ToArray();
            Assert.Equal(newIconHeaderTextData.Length, textDatas[1].Data.Length);
            Assert.Equal(newIconHeaderTextData, textDatas[1].Data);
        }
    }
}