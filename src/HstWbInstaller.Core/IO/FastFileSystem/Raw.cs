namespace HstWbInstaller.Core.IO.FastFileSystem
{
    using System;
    using System.IO;
    using System.Threading.Tasks;
    using RigidDiskBlocks;

    public static class Raw
    {
        /*
 * adfReadRootBlock
 *
 * ENDIAN DEPENDENT
 */
        public static async Task<RootBlock> AdfReadRootBlock(Volume vol, int nSect)
        {
            //uint8_t buf[LOGICAL_BLOCK_SIZE];

            var buf = await Disk.AdfReadBlock(vol, nSect);
//             if (adfReadBlock(vol, nSect, buf)!=RC_OK)
//                 return RC_ERROR;
//
//             memcpy(root, buf, LOGICAL_BLOCK_SIZE);
// #ifdef LITT_ENDIAN
//             swapEndian((uint8_t*)root, SWBL_ROOT);    
// #endif

            var root = await RootBlockReader.Parse(buf);
            root.BlockBytes = buf;
            root.HeaderKey = nSect;
            root.Offset = (uint)nSect;

            if (root.Type != Constants.T_HEADER || root.SecType != Constants.ST_ROOT) {
                throw new IOException("adfReadRootBlock : id not found");
            }
            // if (root->checkSum!=adfNormalSum(buf, 20, LOGICAL_BLOCK_SIZE)) {
            //     throw new IOException("adfReadRootBlock : invalid checksum");
            //     return RC_ERROR;
            // }
		          //
            // return RC_OK;
            return root;
        }
/*
 * adfWriteRootBlock
 *
 * 
 */
        public static async Task AdfWriteRootBlock(Volume vol, int nSect, RootBlock root)
        {
            // uint8_t buf[LOGICAL_BLOCK_SIZE];
            // uint32_t newSum;


            root.Type = Constants.T_HEADER;
            root.HeaderKey = 0;
            root.HighSeq = 0;
            root.HashTableSize = Constants.HT_SIZE;
            root.FirstData = 0;
            /* checkSum, hashTable */
            /* bmflag */
            /* bmPages, bmExt */
            root.NextSameHash = 0;
            root.Parent = 0;
            root.SecType = Constants.ST_ROOT;

//             memcpy(buf, root, LOGICAL_BLOCK_SIZE);
// #ifdef LITT_ENDIAN
//             swapEndian(buf, SWBL_ROOT);
// #endif
            var buf = await RootBlockWriter.BuildBlock(root, vol.BlockSize);

            //newSum = AdfNormalSum(buf, 20, (int)vol.BlockSize);
            //swLong(buf+20, newSum);
/*	*(uint32_t*)(buf+20) = swapLong((uint8_t*)&newSum);*/

/* 	dumpBlock(buf);*/
            await Disk.AdfWriteBlock(vol, nSect, buf);
/*printf("adfWriteRootBlock %ld\n",nSect);*/
        }        
/*
 * NormalSum
 *
 * buf = where the block is stored
 * offset = checksum place (in bytes)
 * bufLen = buffer length (in bytes)
 */
        public static uint AdfNormalSum(byte[] buf, int offset, int bufLen)
        {
            var longBytes = new byte[4];
            var newsum = 0;
            for(var i=0; i < bufLen/4; i++)
                if (i != offset / 4)
                {
                    Array.Copy(buf, i * 4, longBytes, 0, 4);
                    newsum += LittleEndianConverter.ConvertToInt32(longBytes);
                }/* old chksum */
                    
            newsum=(-newsum);	/* WARNING */

            return (uint)newsum;
        }

        public static void UpdateChecksum(byte[] blockBytes, int checksumOffset, uint checksum)
        {
            // swLong(buf+20, newSum);
            var checksumBytes = LittleEndianConverter.ConvertToBytes(checksum);
            Array.Copy(checksumBytes, 0, blockBytes, checksumOffset, checksumBytes.Length);
        }
    }
}