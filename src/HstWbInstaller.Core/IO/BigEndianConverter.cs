namespace HstWbInstaller.Core.IO
{
    public static class BigEndianConverter
    {
        public static short ConvertBytesToInt16(byte[] bytes, int offset = 0)
        {
            return (short)(bytes[offset + 1] & 0x00ff | (bytes[offset] << 8) & 0xff00);
        }
        
        public static int ConvertBytesToInt32(byte[] bytes, int offset = 0)
        {
            return (int)(bytes[offset + 3] & 0x000000ff) | 
                   (int)((bytes[offset + 2] << 8) & 0x0000ff00) | 
                   (int)((bytes[offset + 1] << 16) & 0x00ff0000) |
                   (int)((bytes[offset] << 24) & 0xff000000);
        }

        public static uint ConvertBytesToUInt16(byte[] bytes, int offset = 0)
        {
            return bytes[offset + 1] + 
                   (uint)(bytes[offset] << 8);
        }

        public static uint ConvertBytesToUInt32(byte[] bytes, int offset = 0)
        {
            return bytes[offset + 3] + 
                   (uint)(bytes[offset + 2] << 8) + 
                   (uint)(bytes[offset + 1] << 16) + 
                   (uint)(bytes[offset] << 24);
        }
        
        public static byte[] ConvertUInt16ToBytes(ushort value)
        {
            var data = new byte[2];
            ConvertUInt16ToBytes(value, data, 0);
            return data;
        }
        
        public static void ConvertUInt16ToBytes(ushort value, byte[] data, int offset)
        {
            data[offset] = (byte)((value >> 8) & 0xFF);
            data[offset + 1] = (byte)(value & 0xFF);
        }
        
        public static byte[] ConvertUInt32ToBytes(uint value)
        {
            var data = new byte[4];
            ConvertUInt32ToBytes(value, data, 0);
            return data;
        }

        public static void ConvertUInt32ToBytes(uint value, byte[] data, int offset)
        {
            data[offset] = (byte)((value >> 24) & 0xFF);
            data[offset + 1] = (byte)((value >> 16) & 0xFF);
            data[offset + 2] = (byte)((value >> 8) & 0xFF);
            data[offset + 3] = (byte)(value & 0xFF);
        }
        
        public static byte[] ConvertInt16ToBytes(short value)
        {
            var data = new byte[2];
            ConvertInt16ToBytes(value, data, 0);
            return data;
        }

        public static void ConvertInt16ToBytes(short value, byte[] data, int offset)
        {
            data[offset] = (byte)((value >> 8) & 0xFF);
            data[offset + 1] = (byte)(value & 0xFF);
        }
        
        public static byte[] ConvertInt32ToBytes(int value)
        {
            var data = new byte[4];
            ConvertInt32ToBytes(value, data, 0);
            return data;
        }

        public static void ConvertInt32ToBytes(int value, byte[] data, int offset)
        {
            data[offset] = (byte)((value >> 24) & 0xFF);
            data[offset + 1] = (byte)((value >> 16) & 0xFF);
            data[offset + 2] = (byte)((value >> 8) & 0xFF);
            data[offset + 3] = (byte)(value & 0xFF);
        }
    }
}