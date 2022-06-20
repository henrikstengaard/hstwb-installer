namespace HstWbInstaller.Core.IO.Images.Bitmap
{
    public class BitmapInfoHeader
    {
        public uint HeaderSize { get; set; }
        public int ImageWidth { get; set; }
        public int ImageHeight { get; set; }
        public ushort Planes { get; set; }
        public ushort BitsPerPixel { get; set; }
        public uint Compression { get; set; }
        public uint ImageSize { get; set; }
        public int PixelsPerMeterHorizontal { get; set; }
        public int PixelsPerMeterVertical { get; set; }
        public uint TotalColors { get; set; }
        public uint ImportantColors { get; set; }

        public BitmapInfoHeader()
        {
            Planes = 1;
            HeaderSize = SizeOf.BitmapInfoHeader;
            Compression = 0; // 0 to represent no-compression is used
            ImageSize = 0; // 0 when no compression algorithm is used
            PixelsPerMeterHorizontal = 0;
            PixelsPerMeterVertical = 0;
            ImportantColors = 0;
        }
    }
}