namespace HstWbInstaller.Core.IO.FastFileSystem
{
    using System;

    public static class MapBlockHelper
    {
        /// <summary>
        /// Convert map for blocks to byte array
        /// </summary>
        /// <param name="map"></param>
        /// <returns></returns>
        public static byte[] ConvertMapToByteArray(bool[] map)
        {
            var bytes = new byte[map.Length / 8];
            for (int byteOffset = 0, bitOffset = 0; bitOffset < map.Length; byteOffset++, bitOffset += 8)
            {
                for (int offset = 0; offset < 8; offset++)
                    bytes[byteOffset] |= (byte)((map[bitOffset + 7 - offset] ? 1 : 0) << offset);
                // for (int offset = 0; offset < 8; offset++)
                //     bytes[byteOffset] |= (byte)((map[bitOffset + offset] ? 1 : 0) << offset);
            }
            
            //Array.Reverse(bytes);
            
            // 1 = 128
            // 2 = 64
            // 3 = 32
            // 4 = 16
            // 5 = 8
            // 6 = 4
            // 7 = 2
            // 8 = 1

            return bytes;
        }
    }
}