namespace HstWbInstaller.Core.Tests
{
    using System.Drawing;
    using System.IO;
    using System.Threading.Tasks;
    using IO.Images;
    using Xunit;
    using ImageConverter = System.Drawing.ImageConverter;

    public class GivenIffImageWriter
    {
        [Fact]
        public async Task WhenWriteImageToThenIffImageIsCreatedAndWritten()
        {
            var image = Image.FromFile(@"TestData\screenshot.png");

            await using var stream = File.Open(@"screenshot.iff", FileMode.Create);
            await IffImageWriter.Write(stream, image);

            var fileInfo = new FileInfo(@"screenshot.iff");
            Assert.True(fileInfo.Exists);
            Assert.NotEqual(0, fileInfo.Length);
        }
    }
}