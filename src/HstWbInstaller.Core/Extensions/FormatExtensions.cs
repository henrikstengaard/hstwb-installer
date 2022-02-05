namespace HstWbInstaller.Core.Extensions
{
    using System;
    using System.Linq;
    using System.Text;

    public static class FormatExtensions
    {
        public static string FormatHex(this byte[] value)
        {
            return string.Join(string.Empty, value.Select(x => $"{x:x2}")).ToUpper();
        }

        public static string FormatHex(this int value)
        {
            var bytes = BitConverter.GetBytes(value);
            Array.Reverse(bytes);
            return bytes.FormatHex();
        }
        
        public static string FormatHex(this uint value)
        {
            var bytes = BitConverter.GetBytes(value);
            Array.Reverse(bytes);
            return bytes.FormatHex();
        }
    }
}