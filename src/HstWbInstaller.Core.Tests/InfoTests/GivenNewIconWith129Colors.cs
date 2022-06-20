namespace HstWbInstaller.Core.Tests.InfoTests
{
    using System.Linq;
    using IO.Info;
    using Xunit;

    public class GivenNewIconWith129Colors
    {
        [Fact]
        public void When()
        {
            var expectedTextDatas = NewIconSize2X2PixelsWith129ColorsTestHelper.CreateTextDatas().ToList();

            var newIcon = NewIconSize2X2PixelsWith129ColorsTestHelper.NewIcon;
            
            var encoder = new IConverterNewIconAsciiEncoder(NewIconSize2X2PixelsWith129ColorsTestHelper.ImageNumber, newIcon);
            var textDatas = encoder.Encode().ToList();
            // var textDatas =
            //     NewIconToolTypesEncoder2.Encode(NewIconSize2X2PixelsWith129ColorsTestHelper.ImageNumber, newIcon);

            var decoder = new NewIconToolTypesDecoder(textDatas);
            var decodedNewIcon = decoder.Decode(NewIconSize2X2PixelsWith129ColorsTestHelper.ImageNumber);
        }
    }
    
    public class GivenNewIconWith50Colors
    {
        [Fact]
        public void When()
        {
            var expectedTextDatas = NewIconSize1X1PixelsWith50ColorsTestHelper.CreateTextDatas().ToList();

            var newIcon = NewIconSize1X1PixelsWith50ColorsTestHelper.NewIcon;
            var imageNumber =  NewIconSize1X1PixelsWith50ColorsTestHelper.ImageNumber;
            
            var encoder = new IConverterNewIconAsciiEncoder(imageNumber, newIcon);
            var textDatas = encoder.Encode().ToList();
            var textDatas2 =
                NewIconToolTypesEncoder2.Encode(imageNumber, newIcon);

            // encoder 2 doesnt properly handle flush/next to next text data
            
            var decoder = new NewIconToolTypesDecoder(textDatas2);
            var decodedNewIcon = decoder.Decode(imageNumber);
        }
    }
    
}