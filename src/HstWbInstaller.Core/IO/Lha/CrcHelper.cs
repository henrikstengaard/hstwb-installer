// namespace HstWbInstaller.Core.IO.Lha
// {
//     // https://github.com/jca02266/lha/blob/03475355bc6311f7f816ea9a88fb34a0029d975b/src/crcio.c
//     public static class CrcHelper
//     {
//         // #define CRCPOLY         0xA001      /* CRC-16 (x^16+x^15+x^2+1) */
//         public const int CRCPOLY = 0xA001;
//         public const int CHAR_BIT = 8;
//         public const int UCHAR_MAX = (1<<8)-1;
//         
//         public static int InitializeCrc()
//         {
//             // #define INITIALIZE_CRC(crc) ((crc) = 0)
//
//             return 0;
//         }
//
//         public static void MakeCrcTable()
//         {
//             var crcTable = new int[UCHAR_MAX + 1];
//             
//             for (var i = 0; i <= UCHAR_MAX; i++) 
//             {
//                 var r = i;
//                 for (var j = 0; j < CHAR_BIT; j++)
//                 {
//                     if (r == 1)
//                     {
//                         r = (r >> 1) ^ CRCPOLY;
//                     }
//                     else
//                     {
//                         r >>= 1;
//                     }
//                 }
//                 crcTable[i] = r;
//             } 
//         }
//
//         public static void UpdateCrc(int crc, int c)
//         {
//             (crctable[((crc) ^ (unsigned char)(c)) & 0xFF] ^ ((crc) >> CHAR_BIT))            
//         }
//         
// /*
// // crcio.c
// #define UPDATE_CRC(crc, c) \
//         (crctable[((crc) ^ (unsigned char)(c)) & 0xFF] ^ ((crc) >> CHAR_BIT))
//  */
//     }
// }