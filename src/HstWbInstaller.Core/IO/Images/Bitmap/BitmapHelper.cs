namespace HstWbInstaller.Core.IO.Images.Bitmap
{
    public static class BitmapHelper
    {
        /// <summary>
        /// Calculate scanline with zero padding to nearest 4-byte boundary
        /// </summary>
        /// <param name="bitsPerPixel"></param>
        /// <param name="width"></param>
        /// <returns></returns>
        public static int CalculateScanline(int bitsPerPixel, int width)
        {
            return ((bitsPerPixel * width + 31) / 32) * 4;
        }
    }
}