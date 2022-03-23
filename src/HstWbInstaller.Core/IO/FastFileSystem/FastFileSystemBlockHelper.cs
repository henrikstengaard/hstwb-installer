namespace HstWbInstaller.Core.IO.FastFileSystem
{
    public static class FastFileSystemBlockHelper
    {
        public static uint CalculateRootBlockOffset(uint lowCyl, uint highCyl, uint reserved, uint heads, uint sectors)
        {
            var cylinders = highCyl - lowCyl + 1;
            var highKey = cylinders * heads * sectors - reserved;
            var rootKey = (reserved + highKey) / 2;
            return rootKey;
        }
    }
}