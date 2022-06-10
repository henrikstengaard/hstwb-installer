namespace HstWbInstaller.Core.Tests
{
    using System.Drawing;
    using System.Drawing.Imaging;
    using IO.Images;
    using Xunit;

    public class GivenImageConverter
    {
        [Fact(Skip = "For testing")]
        public void When()
        {
            var image = (Bitmap)Image.FromFile(@"TestData\screenshot.png");
            var convertedImage = IO.Images.ImageConverter.ConvertTo4BppIndexedImage(image, PixelFormat.Format4bppIndexed);
            
            Assert.Equal(PixelFormat.Format4bppIndexed, convertedImage.PixelFormat);
        }
    }
}