namespace HstWbInstaller.Core.IO.Images.Bitmap
{
    using System;
    using System.IO;

    public static class BitmapImageWriter
    {
        public static void Write(Stream stream, BitmapImage image)
        {
            var binaryWriter = new BinaryWriter(stream);

            var totalColors = Convert.ToInt32(image.BitsPerPixel <= 8 ? Math.Pow(2, image.BitsPerPixel) : 0);
            var pixelDataOffset = SizeOf.BitmapFileHeader + SizeOf.BitmapInfoHeader +
                                  (image.BitsPerPixel <= 8 ? totalColors * 4 : 0);
            var fileSize = (uint)(pixelDataOffset + image.Data.Length);

            // write bitmap file header
            binaryWriter.Write(Constants.BitmapFileType);
            binaryWriter.Write(fileSize);
            binaryWriter.Write((ushort)0); // reserved 1
            binaryWriter.Write((ushort)0); // reserved 2
            binaryWriter.Write(pixelDataOffset);

            // write bitmap info header
            binaryWriter.Write((uint)SizeOf.BitmapInfoHeader);
            binaryWriter.Write((int)image.Width); // width
            binaryWriter.Write((int)image.Height); // height
            binaryWriter.Write((ushort)1); // planes
            binaryWriter.Write((ushort)image.BitsPerPixel); // bits per pixel
            binaryWriter.Write((uint)0); // compression
            binaryWriter.Write((uint)image.Data.Length);
            binaryWriter.Write((int)0); // pixels per meter horizontal
            binaryWriter.Write((int)0); // pixels per meter vertical
            binaryWriter.Write((uint)(image.BitsPerPixel <= 8 ? totalColors : 0)); // total colors
            binaryWriter.Write((uint)0); // important colors

            if (image.BitsPerPixel <= 8)
            {
                // write palette RGB color backwards BGR
                foreach (var color in image.Palette)
                {
                    binaryWriter.Write((byte)color.B); // blue
                    binaryWriter.Write((byte)color.G); // green
                    binaryWriter.Write((byte)color.R); // red
                    binaryWriter.Write((byte)0); // reserved
                }

                // write unused palette colors as zeros
                for (var i = image.Palette.Length; i < totalColors; i++)
                {
                    binaryWriter.Write(new byte[4]);
                }
            }

            binaryWriter.Write(image.Data);
        }
    }
}