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

        // convert ascii bytes to string
        public static string ConvertToAsciiString(byte[] bytes)
        {
            return Ascii.GetString(bytes);
        }

        // convert string to ascii bytes
        public static byte[] ConvertToAsciiBytes(string value)
        {
            return Ascii.GetBytes(value);
        }
        
        // convert iso-8859-1 bytes to string
        public static string ConvertToIso88591String(byte[] bytes)
        {
            return Iso88591.GetString(bytes);
        }

        // convert string to iso-8859-1 bytes
        public static byte[] ConvertToIso88591Bytes(string value)
        {
            return Iso88591.GetBytes(value);
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

        // convert uint16 to little endian bytes 
        public static byte[] ConvertToBytes(ushort value)
        {
            var bytes = BitConverter.GetBytes(value);
            Array.Reverse(bytes);
            return bytes;
        }        
        
        // convert uint32 to little endian bytes 
        public static byte[] ConvertToBytes(uint value)
        {
            var bytes = BitConverter.GetBytes(value);
            Array.Reverse(bytes);
            return bytes;
        }        
        
        // convert int32 to little endian bytes 
        public static byte[] ConvertToBytes(int value)
        {
            var bytes = BitConverter.GetBytes(value);
            Array.Reverse(bytes);
            return bytes;
        }
        
        /*
         * # get little endian unsigned short bytes
function GetLittleEndianUnsignedShortBytes([uint16]$value)
{
	$bytes =[System.BitConverter]::GetBytes($value)
	[Array]::Reverse($bytes)
	return ,$bytes 
}

# get little endian unsigned long bytes
function GetLittleEndianUnsignedLongBytes([uint32]$value)
{
	$bytes =[System.BitConverter]::GetBytes($value)
	[Array]::Reverse($bytes)
	return ,$bytes
}

         */
    }
}