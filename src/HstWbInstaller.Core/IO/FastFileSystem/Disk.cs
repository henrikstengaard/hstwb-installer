namespace HstWbInstaller.Core.IO.FastFileSystem
{
    using System.IO;
    using System.Threading.Tasks;
    using Extensions;

    public static class Disk
    {
        public static async Task<byte[]> ReadBlockBytes(Volume volume, uint sector)
        {
            var byteOffset = volume.PartitionStartOffset + sector * volume.BlockSize;
            volume.Stream.Seek(byteOffset, SeekOrigin.Begin);

            var buffer = new byte[volume.BlockSize];
            var bytesRead = await volume.Stream.ReadAsync(buffer, 0, buffer.Length);

            if (bytesRead != buffer.Length)
            {
                throw new IOException($"Read block bytes only returned {bytesRead} bytes, but expected {volume.BlockSize} bytes");
            }
            
            return buffer;
        }

        public static async Task WriteBlockBytes(Volume volume, uint sector, byte[] buffer)
        {
            var byteOffset = volume.PartitionStartOffset + sector * volume.BlockSize;
            volume.Stream.Seek(byteOffset, SeekOrigin.Begin);
            await volume.Stream.WriteBytes(buffer);
        }
        
        public static async Task<RootBlock> ReadRootBlock(Volume volume, uint sector)
        {
            var blockBytes = await ReadBlockBytes(volume, sector);
            return await RootBlockReader.Parse(blockBytes);
        }
        
        public static async Task<BitmapBlock> ReadBitmapBlock(Volume volume, uint sector)
        {
            var blockBytes = await ReadBlockBytes(volume, sector);
            return await BitmapBlockReader.Parse(blockBytes);
        }
        
        public static async Task<BitmapExtensionBlock> ReadBitmapExtensionBlock(Volume volume, uint sector)
        {
            var blockBytes = await ReadBlockBytes(volume, sector);
            return await BitmapExtensionBlockReader.Parse(blockBytes);
        }

        public static async Task<EntryBlock> AdfReadEntryBlock(Volume volume, int sector)
        {
            // AdfReadEntryBlock
            // https://github.com/lclevy/ADFlib/blob/be8a6f6e8d0ca8fda963803eef77366c7584649a/src/adf_dir.c#L957
            
            var entryBlockOffset = volume.PartitionStartOffset + sector * volume.BlockSize;
            volume.Stream.Seek(entryBlockOffset, SeekOrigin.Begin);
            var entryBlockBytes = await volume.Stream.ReadBytes((int)volume.BlockSize);
            return await EntryBlockReader.Parse(entryBlockBytes);
        }
        
        /*
 * adfReadBlock
 *
 * read logical block
 */
        public static async Task<byte[]> AdfReadBlock(Volume vol, int nSect)
        {
            
            /*    char strBuf[80];*/
            // int32_t pSect;
            // struct nativeFunctions *nFct;
            // RETCODE rc;

            if (!vol.Mounted)
            {
                throw new IOException("the volume isn't mounted, adfReadBlock not possible");
            }
            
            /* translate logical sect to physical sect */
            var pSect = nSect + vol.FirstBlock;

            // if (adfEnv.useRWAccess)
            //     (*adfEnv.rwhAccess)(pSect,nSect,FALSE);
            //
/*printf("psect=%ld nsect=%ld\n",pSect,nSect);*/
/*    sprintf(strBuf,"ReadBlock : accessing logical block #%ld", nSect);	
    (*adfEnv.vFct)(strBuf);
*/
            if (pSect < vol.FirstBlock || pSect > vol.LastBlock)
            {
                throw new IOException("adfReadBlock : nSect out of range");
            }

            return await ReadBlockBytes(vol, (uint)pSect);

            // vol.Stream.Seek(pSect * vol.BlockSize, SeekOrigin.Begin);
            //
            // var buf = new byte[512];
            // var bytesRead = await vol.Stream.ReadAsync(buf, 0, 512);
            //
            // var b = await ReadBlockBytes(vol, (uint)pSect);
            //
            // return bytesRead != 512 ? null : buf;

            /*printf("pSect R =%ld\n",pSect);*/
            // nFct = adfEnv.nativeFct;
            // if (vol->dev->isNativeDev)
            //     rc = (*nFct->adfNativeReadSector)(vol->dev, pSect, 512, buf);
            // else
            //     rc = adfReadDumpSector(vol->dev, pSect, 512, buf);
/*printf("rc=%ld\n",rc);*/
            // if (rc!=RC_OK)
            //     return RC_ERROR;
            // else
            //     return RC_OK;
        }
        
/*
 * isSectNumValid
 *
 */
        public static bool IsSectNumValid(Volume vol, int nSect)
        {
            return 0 <= nSect && nSect <= vol.LastBlock - vol.FirstBlock;
        }
        
/*
 * adfWriteBlock
 *
 */
        public static async Task AdfWriteBlock(Volume vol, int nSect, byte[] buf)
        {
            if (!vol.Mounted) {
                throw new IOException("the volume isn't mounted, adfWriteBlock not possible");
            }

            if (vol.ReadOnly) {
                throw new IOException("adfWriteBlock : can't write block, read only volume");
            }

            var pSect = (int)(nSect + vol.FirstBlock);
/*printf("write nsect=%ld psect=%ld\n",nSect,pSect);*/

            // if (adfEnv.useRWAccess)
            //     (*adfEnv.rwhAccess)(pSect,nSect,TRUE);
 
            if (pSect < vol.FirstBlock || pSect > vol.LastBlock) {
                throw new IOException("adfWriteBlock : nSect out of range");
            }

//             nFct = adfEnv.nativeFct;
// /*printf("nativ=%d\n",vol->dev->isNativeDev);*/
//             if (vol->dev->isNativeDev)
//                 rc = (*nFct->adfNativeWriteSector)(vol->dev, pSect, 512, buf);
//             else
//                 rc = adfWriteDumpSector(vol->dev, pSect, 512, buf);
//
//             if (rc!=RC_OK)
//                 return RC_ERROR;
//             else
//                 return RC_OK;

            await WriteBlockBytes(vol, (uint)pSect, buf);
        }        
    }
}