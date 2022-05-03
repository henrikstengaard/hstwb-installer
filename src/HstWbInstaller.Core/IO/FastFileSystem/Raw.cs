namespace HstWbInstaller.Core.IO.FastFileSystem
{
    using System;
    using RigidDiskBlocks;

    public static class Raw
    {
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
    }
}