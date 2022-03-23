namespace HstWbInstaller.Core.IO
{
    public static class FloppyDiskConstants
    {
        public const int BlockSize = 512;

        public static class DoubleDensity
        {
            public const int Size = 901120;
            public const int Cylinders = 80; // cylinders = size / heads * sectors * block size;
            public const int LowCyl = 0; // start cylinder = 0
            public const int HighCyl = 79; // end cylinder = cylinders - 1
            public const int Heads = 2;
            public const int Sectors = 11;
            public const int ReservedBlocks = 0;
        }
    }
}