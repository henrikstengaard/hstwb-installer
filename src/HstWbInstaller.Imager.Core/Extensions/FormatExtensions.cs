namespace HstWbInstaller.Imager.Core.Extensions
{
    using System;
    using System.Linq;

    public static class FormatExtensions
    {
        public static string FormatBytes(this long size, int precision = 1)
        {
            var unit = Math.Log(size, 1024);
            var units = new[] { "bytes", "KB", "MB", "GB", "TB" };
            var formattedSize = Math.Round(Math.Pow(1024, unit - Math.Floor(unit)), precision);
            var formattedUnit = units[Convert.ToInt32(Math.Floor(unit))];
            return $"{formattedSize} {formattedUnit}";
        }

        public static string FormatHex(this byte[] bytes)
        {
            return string.Join("", bytes.Select(x => $"{x:x2}"));
        }

        public static string FormatHex(this uint value)
        {
            var bytes = BitConverter.GetBytes(value);
            Array.Reverse(bytes);
            return bytes.FormatHex();
        }
    }
}