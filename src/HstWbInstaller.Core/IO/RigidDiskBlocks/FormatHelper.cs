namespace HstWbInstaller.Core.IO.RigidDiskBlocks
{
    using System;
    using System.Linq;
    using System.Text;

    public static class FormatHelper
    {
        public static byte[] FormatDosType(string dosType)
        {
            return FormatDosType(dosType.Substring(0, 3), Convert.ToByte(dosType[3]));
        }

        public static byte[] FormatDosType(string identifier, byte version)
        {
            if (identifier.Length != 3)
            {
                throw new ArgumentException("Identifier must be 3 characters in length", nameof(identifier));
            }

            return Encoding.ASCII.GetBytes(identifier).Concat(new[] { version }).ToArray();
        }
    }
}