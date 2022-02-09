namespace HstWbInstaller.Core.IO.RigidDiskBlocks
{
    using System;

    public static class Size
    {
        public static long FromKiloBytes(long kiloBytes)
        {
            return 1024 * kiloBytes;
        }
        
        public static long FromMegaBytes(long megaBytes)
        {
            return 1024 * 1024 * megaBytes;
        }
        
        public static long FromGigaBytes(long gigaBytes)
        {
            return (long)Math.Pow(10, 9) * gigaBytes;
        }
    }
}