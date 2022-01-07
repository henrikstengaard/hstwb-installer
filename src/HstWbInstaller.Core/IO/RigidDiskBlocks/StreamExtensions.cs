namespace HstWbInstaller.Core.IO.RigidDiskBlocks
{
    using System.IO;
    using System.Threading.Tasks;

    public static class StreamExtensions
    {
        public static async Task<byte[]> ReadBytes(this Stream stream, int count)
        {
            var data = new byte[count];
            await stream.ReadAsync(data, 0, count);
            return data;
        }

        public static async Task<string> ReadMagic(this Stream stream)
        {
            return LittleEndianConverter.ConvertToAsciiString(await stream.ReadBytes(4));
        }

        public static async Task<string> ReadString(this Stream stream, int length)
        {
            return LittleEndianConverter.ConvertToIso88591String(await stream.ReadBytes(length));
        }
        
        public static async Task<int> ReadInt32(this Stream stream)
        {
            return LittleEndianConverter.ConvertToInt32(await stream.ReadBytes(4));
        }

        public static async Task<uint> ReadUInt32(this Stream stream)
        {
            return LittleEndianConverter.ConvertToUInt32(await stream.ReadBytes(4));
        }
    }
}