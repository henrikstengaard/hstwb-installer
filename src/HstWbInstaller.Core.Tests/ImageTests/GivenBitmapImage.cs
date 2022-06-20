namespace HstWbInstaller.Core.Tests.ImageTests
{
    using System.IO;
    using System.Threading.Tasks;
    using IO.Images.Bitmap;
    using Xunit;

    public class GivenBitmapImage
    {
        [Fact]
        public async Task WhenCreateBitmapImageWith8BitsPerPixelThenBytesMatchBitmapFileStructure()
        {
            // arrange - create new bitmap image 
            var image = new BitmapImage(2, 2, 8);

            // act - add palette colors
            image.Palette[0] = new Color
            {
                R = 0,
                G = 0,
                B = 0
            };
            image.Palette[1] = new Color
            {
                R = 255,
                G = 0,
                B = 0
            };

            // act - set pixels
            image.SetPixel(0, 0, 1);
            image.SetPixel(1, 1, 1);

            var bitmapStream = new MemoryStream();
            BitmapImageWriter.Write(bitmapStream, image);

            var bitmapBytes = bitmapStream.ToArray();
            await File.WriteAllBytesAsync("test.bmp", bitmapBytes);

            // assert - read file and info headers
            bitmapStream.Position = 0;
            var binaryReader = new BinaryReader(bitmapStream);
            var fileType = binaryReader.ReadUInt16();
            var fileSize = binaryReader.ReadUInt32();
            binaryReader.ReadUInt16();
            binaryReader.ReadUInt16();
            var pixelDataOffset = binaryReader.ReadUInt32();
            var headerSize = binaryReader.ReadUInt32();
            var imageWidth = binaryReader.ReadInt32();
            var imageHeight = binaryReader.ReadInt32();
            var planes = binaryReader.ReadUInt16();
            var bitsPerPixel = binaryReader.ReadUInt16();
            var compression = binaryReader.ReadUInt32();
            var imageSize = binaryReader.ReadUInt32();
            var pixelsPerMeterHorizontal = binaryReader.ReadInt32();
            var pixelsPerMeterVertical = binaryReader.ReadInt32();
            var totalColors = binaryReader.ReadUInt32();
            var importantColors = binaryReader.ReadUInt32();

            var scanline = ((bitsPerPixel * imageWidth + 31) / 32) * 4;

            Assert.Equal(Constants.BitmapFileType, fileType);
            Assert.Equal(SizeOf.BitmapFileHeader + SizeOf.BitmapInfoHeader + totalColors * 4, pixelDataOffset);
            Assert.Equal(2, imageWidth);
            Assert.Equal(2, imageHeight);
            Assert.Equal(1U, planes);
            Assert.Equal(8U, bitsPerPixel);
            Assert.Equal((uint)SizeOf.BitmapInfoHeader, headerSize);
            Assert.Equal(0U, compression);
            Assert.Equal((uint)(scanline * imageHeight), imageSize);
            Assert.Equal(0, pixelsPerMeterHorizontal);
            Assert.Equal(0, pixelsPerMeterVertical);
            Assert.Equal(256U, totalColors);
            Assert.Equal(0U, importantColors);
            Assert.Equal(SizeOf.BitmapFileHeader + SizeOf.BitmapInfoHeader + (totalColors * 4) + (scanline * imageHeight),
                fileSize);

            // assert - palette color 1 is black
            var b = binaryReader.ReadByte();
            var g = binaryReader.ReadByte();
            var r = binaryReader.ReadByte();
            var unused = binaryReader.ReadByte();
            Assert.Equal(0, r);
            Assert.Equal(0, g);
            Assert.Equal(0, b);
            Assert.Equal(0, unused);

            // assert - palette color 2 is red
            b = binaryReader.ReadByte();
            g = binaryReader.ReadByte();
            r = binaryReader.ReadByte();
            unused = binaryReader.ReadByte();
            Assert.Equal(255, r);
            Assert.Equal(0, g);
            Assert.Equal(0, b);
            Assert.Equal(0, unused);

            // assert - color 3 - 256 is zero
            for (var i = 2; i < 256; i++)
            {
                b = binaryReader.ReadByte();
                g = binaryReader.ReadByte();
                r = binaryReader.ReadByte();
                unused = binaryReader.ReadByte();
                Assert.Equal(0, r);
                Assert.Equal(0, g);
                Assert.Equal(0, b);
                Assert.Equal(0, unused);
            }

            // assert - data matches pixels set with palette colors
            var data = new byte[scanline * imageHeight];
            var dataRead = binaryReader.Read(data, 0, data.Length);
            Assert.Equal(data.Length, dataRead);
            Assert.Equal(new byte[] { 0, 1, 0, 0, 1, 0, 0, 0 }, data);
        }
    }
}