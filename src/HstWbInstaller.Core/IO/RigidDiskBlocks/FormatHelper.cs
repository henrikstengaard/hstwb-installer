namespace HstWbInstaller.Core.IO.RigidDiskBlocks
{
    using System;
    using System.Linq;
    using System.Text;

    public static class FormatHelper
    {
        public static byte[] FormatDosType(string dosType)
        {
            return FormatDosType(dosType.Substring(0, 3), Convert.ToByte(dosType[3] - 48));
        }

        public static byte[] FormatDosType(string identifier, byte version)
        {
            if (identifier.Length != 3)
            {
                throw new ArgumentException("Identifier must be 3 characters in length", nameof(identifier));
            }

            if (version > 9)
            {
                throw new ArgumentException("Version must be between 0 and 9", nameof(version));
            }

            return Encoding.ASCII.GetBytes(identifier).Concat(new[] { version }).ToArray();
        }
    }
}