namespace HstWbInstaller.Core.IO.Images.Bitmap
{
    public class BitmapFileHeader
    {
        public ushort FileType { get; set; }
        public uint FileSize { get; set; }
        public ushort Reserved1 { get; set; }
        public ushort Reserved2 { get; set; }
        public uint PixelDataOffset { get; set; }

        public BitmapFileHeader()
        {
            FileType = Constants.BitmapFileType;
        }
    }
}