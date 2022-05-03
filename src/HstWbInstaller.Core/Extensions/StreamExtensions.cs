namespace HstWbInstaller.Core.Extensions
{
    using System;
    using System.Collections.Generic;
    using System.IO;
    using System.Threading.Tasks;
    using IO.RigidDiskBlocks;

    public static class StreamExtensions
    {
        public static async Task<byte[]> ReadBytes(this Stream stream, int count)
        {
            var data = new byte[count];
            var bytesRead = await stream.ReadAsync(data, 0, count);
            if (bytesRead == 0)
            {
                return Array.Empty<byte>();
            }

            if (bytesRead >= count)
            {
                return data;
            }
            
            var partialData = new byte[bytesRead];
            Array.Copy(data, 0, partialData, 0, bytesRead);
            return partialData;
        }

        public static async Task WriteByte(this Stream stream, byte value)
        {
            var data = new[] { value };
            await stream.WriteAsync(data, 0, data.Length);
        }
        
        public static async Task WriteBytes(this Stream stream, byte[] data)
        {
            await stream.WriteAsync(data, 0, data.Length);
        }

        public static async Task<string> ReadAsciiString(this Stream stream)
        {
            return LittleEndianConverter.ConvertToAsciiString(await stream.ReadBytes(4));
        }

        /// <summary>
        /// Read string first by reading length of string and then read string 
        /// </summary>
        /// <param name="stream"></param>
        /// <param name="length"></param>
        /// <returns></returns>
        public static async Task<string> ReadString(this Stream stream)
        {
            var length = stream.ReadByte();
            return LittleEndianConverter.ConvertToIso88591String(await stream.ReadBytes(length));
        }
        
        public static async Task<string> ReadString(this Stream stream, int length)
        {
            return LittleEndianConverter.ConvertToIso88591String(await stream.ReadBytes(length));
        }

        public static async Task<string> ReadNullTerminatedString(this Stream stream)
        {
            var stringBytes = new List<byte>();

            byte[] buffer = new byte[1];
            int bytesRead;
            do
            {
                bytesRead = await stream.ReadAsync(buffer, 0, 1);
                if (bytesRead == 1 && buffer[0] != 0)
                {
                    stringBytes.Add(buffer[0]);
                }
            } while (bytesRead == 1 && buffer[0] != 0);
            
            return LittleEndianConverter.ConvertToIso88591String(stringBytes.ToArray());
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
            }
        }

        public static async Task WriteStringWithLength(this Stream stream, string value, int maxLength)
        {
            stream.WriteByte((byte)Math.Min(value.Length, maxLength));
            await stream.WriteString(value, maxLength);
        }
        
        public static async Task<short> ReadInt16(this Stream stream)
        {
            return LittleEndianConverter.ConvertToInt16(await stream.ReadBytes(2));
        }

        public static async Task<ushort> ReadUInt16(this Stream stream)
        {
            return LittleEndianConverter.ConvertToUInt16(await stream.ReadBytes(2));
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

        public static async Task WriteLittleEndianInt16(this Stream stream, short value)
        {
            await stream.WriteBytes(LittleEndianConverter.ConvertToBytes(value));
        }
        
        public static async Task WriteLittleEndianInt32(this Stream stream, int value)
        {
            await stream.WriteBytes(LittleEndianConverter.ConvertToBytes(value));
        }

        public static async Task WriteLittleEndianUInt16(this Stream stream, ushort value)
        {
            await stream.WriteBytes(LittleEndianConverter.ConvertToBytes(value));
        }
        
        public static async Task WriteLittleEndianUInt32(this Stream stream, uint value)
        {
            await stream.WriteBytes(LittleEndianConverter.ConvertToBytes(value));
        }
        
        public static async Task<long> Find(this Stream stream, byte[] pattern)
        {
            var chunkSize = 32768;
            byte[] chunk;
            do
            {
                var position = stream.Position;
                chunk = await stream.ReadBytes(chunkSize);

                if (chunk.Length == 0)
                {
                    break;
                }
                
                for (var i = 0; i < chunk.Length; i++)
                {
                    // skip, if first byte is not equal
                    if (chunk[i] != pattern[0])
                    {
                        continue;
                    }
        
                    // found a match on first byte, now try to match rest of the pattern
                    var patternIndex = 1;
                    for (var j = 1; j < pattern.Length; j++, patternIndex++) 
                    {
                        if (j + i >= chunk.Length)
                        {
                            chunk = await stream.ReadBytes(chunkSize);
                            i = 0;
                            patternIndex = 0;
                        }

                        if (chunk[i + patternIndex] != pattern[j])
                        {
                            break;
                        }

                        if (j == pattern.Length - 1)
                        {
                            return position + i;
                        }
                    }
                }
                
            } while (chunk.Length == chunkSize);
            
            return -1;
        }
    }
}