namespace HstWbInstaller.Core.IO.RigidDiskBlocks
{
    using System;
    using System.Text;

    /// <summary>
    /// Little endian converter for reading bits and strings from rigid disk block
    /// </summary>
    public static class LittleEndianConverter
    {
        private static readonly Encoding Ascii = Encoding.ASCII;
        private static readonly Encoding Iso88591 = Encoding.GetEncoding("ISO-8859-1");

        // convert bytes to ascii string
        public static string ConvertToAsciiString(byte[] bytes)
        {
            return Ascii.GetString(bytes);
        }
        
        // convert bytes to iso-8859-1 string
        public static string ConvertToIso88591String(byte[] bytes)
        {
            return Iso88591.GetString(bytes);
        }
        
        // convert bytes from little endian to int32
        public static int ConvertToInt32(byte[] bytes)
        {
            Array.Reverse(bytes);
            return BitConverter.ToInt32(bytes, 0);
        }
        
        // convert bytes from little endian to uint32
        public static uint ConvertToUInt32(byte[] bytes)
        {
            Array.Reverse(bytes);
            return BitConverter.ToUInt32(bytes, 0);
        }        
    }
}