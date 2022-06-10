namespace HstWbInstaller.Core.Tests
{
    using System.Drawing;
    using System.Drawing.Imaging;
    using IO.Images;
    using Xunit;

    public class GivenAgs2ImageConverter
    {
        [Fact]
        public void WhenConvertOcsBackgroundThenColorsAreMappedCorrectlyForAgs2()
        {
            var textColor = Color.FromArgb(255, 255, 255);
            var backgroundColor = Color.FromArgb(1, 1, 1);
            var image = (Bitmap)Image.FromFile(@"TestData\OCS-Background.png");
            var ags2BackgroundImage = Ags2ImageConverter.ConvertToAgs2BackgroundImage(image, PixelFormat.Format4bppIndexed,
                textColor, backgroundColor);
            
            ags2BackgroundImage.Save("ags2_ocs.png");

            var paletteEntries = ags2BackgroundImage.Palette.Entries;
            for (var i = 0; i < 12; i++)
            {
                Assert.Equal(0, paletteEntries[i].A);
                Assert.Equal(0, paletteEntries[i].R);
                Assert.Equal(0, paletteEntries[i].G);
                Assert.Equal(0, paletteEntries[i].B);
            }

            Assert.Equal(backgroundColor.A, paletteEntries[14].A);
            Assert.Equal(backgroundColor.R, paletteEntries[14].R);
            Assert.Equal(backgroundColor.G, paletteEntries[14].G);
            Assert.Equal(backgroundColor.B, paletteEntries[14].B);
            
            Assert.Equal(textColor.A, paletteEntries[15].A);
            Assert.Equal(textColor.R, paletteEntries[15].R);
            Assert.Equal(textColor.G, paletteEntries[15].G);
            Assert.Equal(textColor.B, paletteEntries[15].B);
        }
        
        [Fact]
        public void WhenConvertAgaBackgroundThenColorsAreMappedCorrectlyForAgs2()
        {
            var textColor = Color.FromArgb(255, 255, 255);
            var backgroundColor = Color.FromArgb(0,0,0);
            var image = (Bitmap)Image.FromFile(@"TestData\AGA-Background.png");
            var ags2BackgroundImage = Ags2ImageConverter.ConvertToAgs2BackgroundImage(image, PixelFormat.Format8bppIndexed,
                textColor, backgroundColor);
            
            ags2BackgroundImage.Save("ags2_aga.png");
            
            var paletteEntries = ags2BackgroundImage.Palette.Entries;
            for (var i = 0; i <= 200; i++)
            {
                Assert.Equal(0, paletteEntries[i].A);
                Assert.Equal(0, paletteEntries[i].R);
                Assert.Equal(0, paletteEntries[i].G);
                Assert.Equal(0, paletteEntries[i].B);
            }
            
            Assert.Equal(backgroundColor.A, paletteEntries[254].A);
            Assert.Equal(backgroundColor.R, paletteEntries[254].R);
            Assert.Equal(backgroundColor.G, paletteEntries[254].G);
            Assert.Equal(backgroundColor.B, paletteEntries[254].B);
            
            Assert.Equal(textColor.A, paletteEntries[255].A);
            Assert.Equal(textColor.R, paletteEntries[255].R);
            Assert.Equal(textColor.G, paletteEntries[255].G);
            Assert.Equal(textColor.B, paletteEntries[255].B);
        }
    }
}