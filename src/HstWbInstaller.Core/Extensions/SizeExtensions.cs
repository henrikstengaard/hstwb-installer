namespace HstWbInstaller.Core.Extensions
{
    using System;

    public static class SizeExtensions
    {
        public static long KB(this int size)
        {
            return (long)Math.Pow(10, 3) * size;
        }

        public static long KB(this double size)
        {
            return (long)(Math.Pow(10, 3) * size);
        }
        
        public static long MB(this int size)
        {
            return (long)Math.Pow(10, 6) * size;
        }

        public static long MB(this double size)
        {
            return (long)(Math.Pow(10, 6) * size);
        }
        
        public static long GB(this int size)
        {
            return (long)Math.Pow(10, 9) * size;
        }

        public static long GB(this double size)
        {
            return (long)(Math.Pow(10, 9) * size);
        }
        
        /// <summary>
        /// Convert size to sector size dividable by 512
        /// </summary>
        /// <param name="size"></param>
        /// <returns></returns>
        public static long ToSectorSize(this long size)
        {
            return size % 512 != 0 ? size + (512 - size % 512) : size;
        }
        
        /// <summary>
        /// Convert size to universal size, so it fit's various brands of CF/SD-cards and SSD hard disks
        /// </summary>
        /// <param name="size"></param>
        /// <returns></returns>
        public static long ToUniversalSize(this long size)
        {
            return Convert.ToInt64(size * 0.95d);
        }
    }
}