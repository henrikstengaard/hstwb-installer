namespace HstWbInstaller.Core.IO.Info
{
    public class NewIcon
    {
        public bool Transparent { get; set; }
        public int Width { get; set; }
        public int Height { get; set; }
        public int Depth { get; set; }
        public byte[][] Palette { get; set; }
        public byte[] ImagePixels { get; set; }
    }
}