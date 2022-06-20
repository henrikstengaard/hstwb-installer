namespace HstWbInstaller.Core.Tests.InfoTests
{
    using System.IO;
    using System.Linq;
    using System.Threading.Tasks;
    using IO.Images.Bitmap;
    using IO.Info;
    using SixLabors.ImageSharp.Formats.Png;
    using SixLabors.ImageSharp.PixelFormats;
    using Xunit;
    using Image = SixLabors.ImageSharp.Image;

    public class GivenNewIconEncoderAndDecoder
    {
        [Theory]
        // [InlineData(@"TestData\Info\floppy.png")]
        //[InlineData(@"TestData\Info\Puzzle-Bubble-60-colors.png")]
        // [InlineData(@"TestData\Info\Puzzle-Bubble-100-colors.png")]
        // [InlineData(@"TestData\Info\Puzzle-Bubble-127-colors.png")]
        // [InlineData(@"TestData\Info\Puzzle-Bubble-128-colors.png")]
        // [InlineData(@"TestData\Info\Puzzle-Bubble-129-colors.png")]
        // [InlineData(@"TestData\Info\Puzzle-Bubble-150-colors.png")]
        [InlineData(@"TestData\Info\Puzzle-Bubble-255-colors.png")]
        public async Task WhenEncodeAndDecodeNewIconThen(string imagePath)
        {
            var imageNumber = 1;

            var image = await Image.LoadAsync<Rgba32>(File.OpenRead(imagePath), new PngDecoder());

            var newIcon = NewIconEncoder.Encode(image);

            var encoder = new IConverterNewIconAsciiEncoder(imageNumber, newIcon);
            var textDatasOld = encoder.Encode().ToList();
            var textDatas = NewIconToolTypesEncoder2.Encode(imageNumber, newIcon).ToList();

            var decoder = new NewIconToolTypesDecoder(textDatas);
            var decodedNewIcon = decoder.Decode(imageNumber);
            
            Assert.Equal(newIcon.Width, decodedNewIcon.Width);
            Assert.Equal(newIcon.Height, decodedNewIcon.Height);
            Assert.Equal(newIcon.Depth, decodedNewIcon.Depth);
            Assert.Equal(newIcon.Transparent, decodedNewIcon.Transparent);
            
            Assert.Equal(newIcon.Palette.Length, decodedNewIcon.Palette.Length);
            for (var i = 0; i < newIcon.Palette.Length; i++)
            {
                Assert.Equal(newIcon.Palette[i][0], decodedNewIcon.Palette[i][0]);
                Assert.Equal(newIcon.Palette[i][1], decodedNewIcon.Palette[i][1]);
                Assert.Equal(newIcon.Palette[i][2], decodedNewIcon.Palette[i][2]);
            }
            
            Assert.Equal(newIcon.ImagePixels.Length, decodedNewIcon.ImagePixels.Length);
            for (var i = 0; i < newIcon.ImagePixels.Length; i++)
            {
                if (newIcon.ImagePixels[i] != decodedNewIcon.ImagePixels[i])
                {
                    
                }
                Assert.Equal(newIcon.ImagePixels[i], decodedNewIcon.ImagePixels[i]);
            }
            //
            // var b = NewIconDecoder.DecodeToBitmap(decodedNewIcon);
            // await using var stream = File.OpenWrite("decoded.bmp");
            // BitmapImageWriter.Write(stream, b);
        }
    }
}