namespace HstWbInstaller.Core.Tests.InfoTests
{
    using System.Collections.Generic;
    using System.IO;
    using System.Linq;
    using System.Text;
    using System.Threading.Tasks;
    using IO.Images.Bitmap;
    using IO.Info;
    using SixLabors.ImageSharp.Formats.Bmp;
    using SixLabors.ImageSharp.Formats.Png;
    using SixLabors.ImageSharp.PixelFormats;
    using Xunit;
    using Constants = IO.Info.Constants;
    using Image = SixLabors.ImageSharp.Image;

    public class GivenNewIconToolTypesEncoder
    {
        [Fact]
        public async Task WhenEncodeImagePixelsThenToolTypesMatchIConverterCreatedToolTypes2()
        {
            // arrange - image number, dimension and depth
            const int imageNumber = 1;
            const int width = 8;
            const int height = 8;
            const int depth = 2; // 4 colors (math.pow(2, 2))

            // arrange - palette
            var palette = new[]
            {
                new byte[] { 170, 170, 170, 255 },
                new byte[] { 0, 0, 0, 255 },
                new byte[] { 255, 255, 255, 255 },
                new byte[] { 102, 136, 187, 255 },
            };

            // arrange - image pixels 
            var imagePixels = new byte[]
            {
                0, 0, 0, 0, 1, 1, 1, 1,
                0, 0, 0, 0, 1, 1, 1, 1,
                0, 0, 0, 0, 1, 1, 1, 1,
                0, 0, 0, 0, 1, 1, 1, 1,
                2, 2, 2, 2, 3, 3, 3, 3,
                2, 2, 2, 2, 3, 3, 3, 3,
                2, 2, 2, 2, 3, 3, 3, 3,
                2, 2, 2, 2, 3, 3, 3, 3
            };

            // arrange - load iconverter created newicon info
            await using var stream = File.OpenRead(@"TestData\Info\Drawer-NewIcon-IConverter.info");
            var diskObject = await DiskObjectReader.Read(stream);

            // arrange - get im1 tooltypes
            var expectedToolTypes =
                diskObject.ToolTypes.TextDatas.Where(
                    x => x.Size >= 4 && Encoding.ASCII.GetString(x.Data, 0, 4) == "IM1=").ToList();

            // // act - encode palette, image pixels and get tool types
            // var encoder = new NewIconToolTypesEncoder(imageNumber, width, height, depth, false);
            // encoder.EncodePalette(palette);
            // encoder.EncodeImage(imagePixels);
            // var toolTypes = encoder.GetToolTypes().ToList();
            //
            // // assert - tool types are equal 
            // Assert.Equal(expectedToolTypes.Count, toolTypes.Count);
            // for (var i = 0; i < expectedToolTypes.Count; i++)
            // {
            //     Assert.Equal(expectedToolTypes[i].Size, toolTypes[i].Size);
            //     Assert.Equal(expectedToolTypes[i].Data, toolTypes[i].Data);
            // }
        }

        private byte[] T()
        {
            var imageNumber = 1;
            var paletteDepth = 8;

            var textData = new List<byte>(Encoding.ASCII.GetBytes($"IM{imageNumber}="));
            var bytes = new byte[] { 255, 0, 0, 0, 255, 0 };

            byte pendingBits = 0;

            var bitsInUse = 8;
            var bitsLeft = 7;

            var bitMasks = new[]
            {
                255, // 
                127, // except 128
                63, // except 128, 64
                31, // except 128, 64, 32
                15, // except 128, 64, 32, 16
                7, // except 128, 64, 32, 16, 8
                3, // // except 128, 64, 32, 16, 4
                1, // // except 128, 64, 32, 16, 4, 2
                0
            };

            foreach (var value in bytes)
            {
                var remainingBits = bitsInUse - bitsLeft;
                pendingBits |= (byte)(value >> remainingBits);
                bitsLeft -= bitsInUse;

                if (bitsLeft <= 0)
                {
                    textData.Add(AsciiEncodeBits(pendingBits));

                    pendingBits = (byte)(bitsLeft < 0 ? (value ^ bitMasks[remainingBits]) >> remainingBits : 0);

                    bitsLeft += 7;
                }


                // currentValue = AsciiEncodeBits(currentValue);
                // textData.Add(currentValue);
            }

            return null;
        }


        public IEnumerable<TextData> CreateExpectedTextDatas(int imageNumber, NewIcon newIcon)
        {
            var textDatas = new List<TextData>();

            var headerBytes = Encoding.ASCII.GetBytes($"IM{imageNumber}=");

            var textData = new List<byte>(headerBytes);

            textData.Add((byte)(0x21 + (newIcon.Transparent ? 33 : 34)));
            textData.Add((byte)(0x21 + newIcon.Width));
            textData.Add((byte)(0x21 + newIcon.Height));
            textData.Add((byte)(0x21 + (newIcon.Palette.Length >> 6)));
            textData.Add((byte)(0x21 + (newIcon.Palette.Length & 0x3f)));

            var bitsLeft = 7;
            byte currentValue = 0;

            var paletteBytes = newIcon.Palette[0].Concat(newIcon.Palette[1]).ToArray();
            foreach (var value in paletteBytes)
            {
                currentValue |= (byte)(value >> (8 - bitsLeft));

                // ascii encode bits
                currentValue = AsciiEncodeBits(currentValue);

                textData.Add(currentValue);
                bitsLeft -= 1;

                currentValue = (byte)((value << bitsLeft) & 0x7f);

                if (bitsLeft == 0)
                {
                    currentValue = (byte)(value & 0x7f);

                    // ascii encode bits
                    currentValue = AsciiEncodeBits(currentValue);

                    textData.Add(currentValue);

                    currentValue = 0;
                    bitsLeft = 7;
                }
            }

            // flush remaining bits
            if (bitsLeft < 7)
            {
                currentValue = AsciiEncodeBits(currentValue);
                textData.Add(currentValue);
            }

            // add text data to list and clear
            textData.Add(0);
            textDatas.Add(new TextData
            {
                Data = textData.ToArray(),
                Size = (uint)textData.Count
            });
            textData.Clear();

            textData.AddRange(headerBytes);
            currentValue = 0;
            bitsLeft = 7;

            foreach (var value in newIcon.ImagePixels)
            {
                if (bitsLeft < newIcon.Depth)
                {
                    currentValue |= (byte)(value >> (newIcon.Depth - bitsLeft));
                    bitsLeft += 7;

                    currentValue = AsciiEncodeBits(currentValue);
                    textData.Add(currentValue);

                    currentValue = 0;
                }

                bitsLeft -= newIcon.Depth;
                currentValue |= (byte)((value << bitsLeft) & 0x7f);

                var bytesLeft = Constants.NewIcon.MAX_STRING_LENGTH - textData.Count;
                if (bytesLeft == 0 && bitsLeft < newIcon.Depth)
                {
                    currentValue = AsciiEncodeBits(currentValue);
                    textData.Add(currentValue);
                }
            }

            // flush remaining bits
            if (bitsLeft < 7)
            {
                currentValue = AsciiEncodeBits(currentValue);
                textData.Add(currentValue);
            }

            // add text data to list and clear
            textData.Add(0);
            textDatas.Add(new TextData
            {
                Data = textData.ToArray(),
                Size = (uint)textData.Count
            });
            textData.Clear();

            return textDatas;
        }

        private byte[] GetHeader(int imageNumber)
        {
            return Encoding.ASCII.GetBytes($"IM{imageNumber}=");
        }

        private byte AsciiEncodeBits(byte value)
        {
            return value < 0x50 ? (byte)(value + 0x20) : (byte)(value + 0x51);
        }


        [Fact]
        public async Task WhenEncodeImagePixelsFromPngThenToolTypesMatch()
        {
            // arrange - paths
            // var firstImagePath = @"TestData\Info\floppy.png";
            var firstImagePath = @"TestData\Info\Puzzle-Bubble3.png";
            //var secondImagePath = @"TestData\Info\bubble_bobble2.png";

            // arrange - read first and second images
            var firstImage = await Image.LoadAsync<Rgba32>(File.OpenRead(firstImagePath), new PngDecoder());
            //var secondImage = await Image.LoadAsync<Rgba32>(File.OpenRead(secondImagePath), new PngDecoder());

            // var firstImagePath = @"TestData\Info\Flashback-image1.bmp";
            // var secondImagePath = @"TestData\Info\Flashback-image2.bmp";
            // var firstImage = await Image.LoadAsync<Rgba32>(File.OpenRead(firstImagePath), new BmpDecoder());
            // var secondImage = await Image.LoadAsync<Rgba32>(File.OpenRead(secondImagePath), new BmpDecoder());

            // arrange - encode new icon image
            var firstNewIcon = NewIconEncoder.Encode(firstImage);
            //var secondNewIcon = NewIconEncoder.Encode(secondImage);

            // act - encode palette, image pixels and get tool types
            // var firstNewIconEncoder = new NewIconToolTypesEncoder(1, firstNewIcon.Width, firstNewIcon.Height,
            //     firstNewIcon.Depth, firstNewIcon.Transparent);
            // firstNewIconEncoder.EncodePalette(firstNewIcon.Palette);
            // firstNewIconEncoder.EncodeImage(firstNewIcon.ImagePixels);
            // var firstNewIconToolTypes = firstNewIconEncoder.GetToolTypes().ToList();

            // var image1TextDatas =
            //     diskObject.ToolTypes.TextDatas.Where(x =>
            //             x.Size >= 4 && Encoding.ASCII.GetString(x.Data, 0, 4) == $"IM1=")
            //         .ToList();
            //
            var defaultImage = TestDataHelper.CreateFirstImage();

            var floppyDiskObject = InfoHelper.CreateProjectInfo();
            InfoHelper.SetFirstImage(floppyDiskObject, TestDataHelper.Palette, defaultImage, TestDataHelper.Depth);
            // InfoHelper.SetSecondImage(newDiskObject, TestDataHelper.Palette, defaultImage, TestDataHelper.Depth);
            NewIconHelper.SetNewIconImage(floppyDiskObject, 1, firstNewIcon);
            //NewIconHelper.SetNewIconImage(floppyDiskObject, 2, secondNewIcon);

            await using var newStream = File.Open("bubble_bobble-255c.info", FileMode.Create);
            await DiskObjectWriter.Write(floppyDiskObject, newStream);

            //newDiskObject.Gadget.

            // assert - tool types are equal 
            // Assert.Equal(expectedToolTypes.Count, toolTypes.Count);
            // for (var i = 0; i < expectedToolTypes.Count; i++)
            // {
            //     Assert.Equal(expectedToolTypes[i].Size, toolTypes[i].Size);
            //     Assert.Equal(expectedToolTypes[i].Data, toolTypes[i].Data);
            // }
        }

        [Fact]
        public async Task TTt()
        {
            var imagePath = @"TestData\Info\floppy.png";
            var imageNumber = 1;

            var image = await Image.LoadAsync<Rgba32>(File.OpenRead(imagePath), new PngDecoder());

            var newIcon = NewIconEncoder.Encode(image);

            var encoder = new IConverterNewIconAsciiEncoder(imageNumber, newIcon);
            var textDatas1 = encoder.Encode().ToList();
            var textDatas2 = NewIconToolTypesEncoder2.Encode(imageNumber, newIcon).ToList();


            Assert.Equal(textDatas1.Count, textDatas2.Count);
            for (var i = 0; i < textDatas1.Count; i++)
            {
                Assert.Equal(textDatas1[i].Data.Length, textDatas2[i].Data.Length);

                for (var d = 0; d < textDatas1[i].Data.Length; d++)
                {
                    if (textDatas1[i].Data[d] != textDatas2[i].Data[d])
                    {
                    }
                }

                Assert.Equal(textDatas1[i].Size, textDatas2[i].Size);
                Assert.Equal(textDatas1[i].Data, textDatas2[i].Data);
            }

            // var decoder = new NewIconToolTypesDecoder(textDatas);
            // var decodedNewIcon = decoder.Decode(imageNumber);
            //
            // var b = NewIconDecoder.DecodeToBitmap(decodedNewIcon);
            // await using var stream = File.OpenWrite("decoded.bmp");
            // BitmapImageWriter.Write(stream, b);
        }
    }
}