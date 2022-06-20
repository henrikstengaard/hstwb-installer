namespace HstWbInstaller.Core.IO.Images.Bitmap
{
    using System.Collections.Generic;
    using System.IO;

    public static class BitmapImageReader
    {
        public static BitmapImage Read(Stream stream)
        {
            var binaryReader = new BinaryReader(stream);
            
            var fileType = binaryReader.ReadUInt16();
            var fileSize = binaryReader.ReadUInt32();
            binaryReader.ReadUInt16(); // reserved 1
            binaryReader.ReadUInt16(); // reserved 2
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
            
            // read palette
            var palette = new List<Color>();
            if (bitsPerPixel <= 8)
            {
                for (var i = 0; i < totalColors; i++)
                {
                    var b = binaryReader.ReadByte();
                    var g = binaryReader.ReadByte();
                    var r = binaryReader.ReadByte();
                    binaryReader.ReadByte(); // reserved
                    
                    palette.Add(new Color
                    {
                        R = r,
                        G = g,
                        B = b,
                        A = 255
                    });
                }
            }

            var data = new byte[imageSize];
            if (binaryReader.Read(data, 0, (int)imageSize) != imageSize)
            {
                throw new IOException($"Unable to read image data of length {imageSize}");
            }

            return new BitmapImage(imageWidth, imageHeight, bitsPerPixel, palette, data);
        }
    }
}