namespace HstWbInstaller.Core.IO.Info
{
    using Images.Bitmap;

    public class ColorIconImage
    {
        public int Width { get; set; }
        public int Height { get; set; }
        public Color[] Palette { get; set; }
        public byte[] Pixels { get; set; }
    }
}