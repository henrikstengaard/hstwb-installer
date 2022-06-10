namespace HstWbInstaller.Core.IO.Lha
{
    public static class ChecksumHelper
    {
        public static int CalcSum(byte[] p, int offset, int len)
        {
            var sum = 0;

            for (var i = offset; i < offset + len; i++)
            {
                sum += p[i];
            }

            return sum & 0xff;
        }
    }
}