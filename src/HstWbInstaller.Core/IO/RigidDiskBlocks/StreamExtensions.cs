namespace HstWbInstaller.Core.IO.RigidDiskBlocks
{
    using System.IO;
    using System.Security.Cryptography.X509Certificates;
    using System.Threading.Tasks;

    public static class StreamExtensions
    {
        public static async Task<byte[]> ReadBytes(this Stream stream, int count)
        {
            var data = new byte[count];
            await stream.ReadAsync(data, 0, count);
            return data;
        }

        public static async Task WriteBytes(this Stream stream, byte[] data)
        {
            await stream.WriteAsync(data, 0, data.Length);
        }

        public static async Task<string> ReadAsciiString(this Stream stream)
        {
            return LittleEndianConverter.ConvertToAsciiString(await stream.ReadBytes(4));
        }

        public static async Task<string> ReadString(this Stream stream, int length)
        {
            return LittleEndianConverter.ConvertToIso88591String(await stream.ReadBytes(length));
        }

        public static async Task WriteString(this Stream stream, string value, int length, byte fillByte = 0)
        {
            var bytes = LittleEndianConverter.ConvertToIso88591Bytes(value.Length > length
                ? value.Substring(0, length)
                : value);

            await stream.WriteBytes(bytes);
            
            if (bytes.Length < length)
            {
                var fillBytes = new byte[length - bytes.Length];
                for (var i = 0; i < fillBytes.Length; i++)
                {
                    fillBytes[i] = fillByte;
                }
                await stream.WriteBytes(fillBytes);
                // var zeroFilledBytes = new MemoryStream(new byte[length]);
                // await zeroFilledBytes.WriteBytes(bytes);
                // bytes = zeroFilledBytes.ToArray();
            }
        }

        public static async Task<int> ReadInt32(this Stream stream)
        {
            return LittleEndianConverter.ConvertToInt32(await stream.ReadBytes(4));
        }

        public static async Task<uint> ReadUInt32(this Stream stream)
        {
            return LittleEndianConverter.ConvertToUInt32(await stream.ReadBytes(4));
        }

        public static async Task WriteAsciiString(this Stream stream, string value)
        {
            await stream.WriteBytes(LittleEndianConverter.ConvertToAsciiBytes(value));
        }

        public static async Task WriteLittleEndianInt32(this Stream stream, int value)
        {
            await stream.WriteBytes(LittleEndianConverter.ConvertToBytes(value));
        }

        public static async Task WriteLittleEndianUInt32(this Stream stream, uint value)
        {
            await stream.WriteBytes(LittleEndianConverter.ConvertToBytes(value));
        }
    }
}