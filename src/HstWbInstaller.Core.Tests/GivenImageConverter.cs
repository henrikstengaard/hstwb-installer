namespace HstWbInstaller.Core.Tests
{
    using System.Drawing;
    using System.Drawing.Imaging;
    using IO.Images;
    using Xunit;

    public class GivenImageConverter
    {
        [Fact]
        public void When()
        {
            var image = (Bitmap)Image.FromFile(@"TestData\screenshot.png");
            var cpnvertedImage = IO.Images.ImageConverter.ConvertTo4BppIndexedImage(image, PixelFormat.Format4bppIndexed);
        }
        
        [Fact]
        public void When2()
        {
            var image = (Bitmap)Image.FromFile(@"TestData\AGA-Background.png");
            var ags2BackgroundImage = Ags2ImageConverter.ConvertToAgs2BackgroundImage(image, PixelFormat.Format8bppIndexed,
                Color.White, Color.Black);
            
            ags2BackgroundImage.Save("ags2.png");
        }
    }
}