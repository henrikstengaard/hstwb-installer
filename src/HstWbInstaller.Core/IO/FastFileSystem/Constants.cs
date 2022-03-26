namespace HstWbInstaller.Core.IO.FastFileSystem
{
    public class Constants
    {
        public const int BitmapsPerLong = 8 * IO.Constants.LongSize;
        public const int MaxBitmapBlockPointersInRootBlock = 25;
    }
}