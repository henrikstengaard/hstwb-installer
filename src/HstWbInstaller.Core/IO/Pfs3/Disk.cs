namespace HstWbInstaller.Core.IO.Pfs3
{
    using System;
    using System.IO;
    using System.Threading.Tasks;
    using Blocks;
    using Extensions;

    public static class Disk
    {
        // disk.c

        public static bool RawRead(uint blocks, uint blocknr, globaldata g, out IBlock blk)
        {
            throw new IOException("not implemented!");
            // seek to block in stream
            

            // read block bytes
            var buffer = new byte[512 * blocks];
            var bytesRead = g.stream.Read(buffer, 0, buffer.Length);
            throw new NotImplementedException();

            // parse data to block

            return true;
        }

        public static bool RawWrite(Stream stream, IBlock block, uint blocks, uint blocknr, globaldata g)
        {
            throw new IOException("not implemented!");
            // RawReadWrite_DS(TRUE, buffer, blocks, blocknr, g);
            
            if(blocknr == -1)   // blocknr of uninitialised anode
                return false;

            blocknr += g.firstblock;

            if (g.softprotect)
            {
                throw new IOException("ERROR_DISK_WRITE_PROTECTED");
            }

            // if (!BoundsCheck(write, blocknr, blocks, g))
            // {
            //     throw new IOException("ERROR_SEEK_ERROR");
            // }
            
            // seek
            stream.Seek(512 * blocknr, SeekOrigin.Begin);

            //await stream.WriteBytes(buffer);

            return true;
        }
    }
}