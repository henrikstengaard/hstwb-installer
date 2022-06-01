namespace HstWbInstaller.Core
{
    using System.Text;

    public static class AmigaTextHelper
    {
        private static readonly Encoding Iso88591 = Encoding.GetEncoding("ISO-8859-1");

        public static string GetString(byte[] bytes, int index = 0, int count = 0)
        {
            return Iso88591.GetString(bytes, index, count == 0 ? bytes.Length : count);
        }
        
        public static byte[] GetBytes(string value)
        {
            return Iso88591.GetBytes(value);
        }
    }
}