namespace HstWbInstaller.Core.IO.FastFileSystem
{
    using System;
    using System.Collections.Generic;

    public static class MapBlockHelper
    {
        /// <summary>
        /// Convert block free map to byte array. One bit is used per block. If the bit is set, the block is free, a cleared bit means an allocated block.
        ///           3         2         1 
        /// Blocks: 21098765432109876543210987654321
        /// Bits:   11111111111111110011111111111111
        /// </summary>
        /// <param name="blockFreeMap"></param>
        /// <returns></returns>
        public static byte[] ConvertBlockFreeMapToByteArray(bool[] blockFreeMap)
        {
            var length = blockFreeMap.Length % 8 != 0 ? Convert.ToInt32(Math.Ceiling((double)blockFreeMap.Length / 8)) : blockFreeMap.Length / 8;
            
            var bytes = new byte[length];
            for (int byteOffset = 0, bitOffset = 0; byteOffset < length; byteOffset++, bitOffset += 8)
            {
                for (int offset = 0; offset < 8 && bitOffset + offset < blockFreeMap.Length ; offset++)
                    bytes[byteOffset] |= (byte)((blockFreeMap[bitOffset + offset] ? 1 : 0) << offset);
            }
            
            Array.Reverse(bytes);

            return bytes;
        }
        
        public static bool[] ConvertByteArrayToBlockFreeMap(byte[] byteArray)
        {
            var blockFreeMap = new List<bool>();
            for (int byteOffset = byteArray.Length - 1; byteOffset >= 0; byteOffset--)
            {
                for (int bitOffset = 0; bitOffset < 8; bitOffset++)
                {
                    blockFreeMap.Add((byteArray[byteOffset] & 1 << bitOffset) != 0);
                }
            }
            return blockFreeMap.ToArray();
        }
    }
}