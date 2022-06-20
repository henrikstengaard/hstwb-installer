namespace HstWbInstaller.Core.Tests.InfoTests
{
    using System.Linq;
    using IO.Info;
    using Xunit;

    public class GivenNewIconOfSize2X2PixelsWith2Colors
    {
        [Fact]
        public void WhenEncodeNewIconThenBytesMatch()
        {
            // arrange - create expected text datas
            var expectedTextDatas = NewIconSize2X2PixelsWith2ColorsTestHelper.CreateTextDatas().ToList();

            // act - encode palette, image pixels and get tool types
            //var encoder = new NewIconToolTypesEncoder(NewIconSize2X2PixelsWith2ColorsTestHelper.ImageNumber, 
            //    NewIconSize2X2PixelsWith2ColorsTestHelper.NewIcon);
            //var textDatas = encoder.Encode().ToList();
            var textDatas = NewIconToolTypesEncoder2.Encode(
                NewIconSize2X2PixelsWith2ColorsTestHelper.ImageNumber,
                NewIconSize2X2PixelsWith2ColorsTestHelper.NewIcon).ToList();

            // assert - text datas are equal 
            Assert.Equal(expectedTextDatas.Count, textDatas.Count);
            for (var i = 0; i < expectedTextDatas.Count; i++)
            {
                Assert.Equal(expectedTextDatas[i].Size, textDatas[i].Size);
                Assert.Equal(expectedTextDatas[i].Data, textDatas[i].Data);
            }
        }
    }
}