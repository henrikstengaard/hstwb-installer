namespace HstWbInstaller.Core.Extensions
{
    using System;
    using System.Text;
    using IO.RigidDiskBlocks;

    public static class ByteArrayExtensions
    {
        private static readonly Encoding Iso88591Encoding = Encoding.GetEncoding("ISO-8859-1");
        
        public static byte[] CopyBytes(this byte[] bytes, int offset, int length)
        {
            var data = new byte[length];
            Array.Copy(bytes, offset, data, 0, length);
            return data;
        }
        
        public static uint ReadLittleEndianUInt32(this byte[] bytes, int offset)
        {
            return LittleEndianConverter.ConvertToUInt32(bytes.CopyBytes(offset, 4));
        }

        public static string ReadNullTerminatedString(this byte[] bytes, int offset = 0)
        {
            var index = 0;
            for (index = offset; index < bytes.Length; index++)
            {
                if (bytes[index] == 0)
                {
                    break;
                }
            }

            var length = index - offset;
            if (length <= 0)
            {
                return string.Empty;
            }
            
            var stringBytes = new byte[length];
            Array.Copy(bytes, offset, stringBytes, 0, length);
            
            return LittleEndianConverter.ConvertToIso88591String(stringBytes);
        }

        public static string FormatDosType(this byte[] bytes)
        {
            if (bytes.Length != 4)
            {
                throw new ArgumentException("Invalid dos type");
            }
            
            var dosIdentifier = new byte[3];
            Array.Copy(bytes, 0, dosIdentifier, 0, 3);
            return $"{Iso88591Encoding.GetString(dosIdentifier)}\\{bytes[3]}";
        }
    }
}