namespace HstWbInstaller.Core.IO.FastFileSystem
{
    using System;

    public static class Cache
    {
        public static void AdfAddInCache(Volume vol, IEntryBlock parent, IEntryBlock entry)
        {
            // https://github.com/lclevy/ADFlib/blob/be8a6f6e8d0ca8fda963803eef77366c7584649a/src/adf_cache.c#L354
            throw new NotImplementedException();
        }
    }

    public static class Bitmap
    {
        /*
 * adfUpdateBitmap
 *
 */
        public static void AdfUpdateBitmap(Volume vol)
        {
            throw new NotImplementedException();
//             int i;
//             struct bRootBlock root;
//
// /*printf("adfUpdateBitmap\n");*/
//         
//             if (adfReadRootBlock(vol, vol->rootBlock,&root)!=RC_OK)
//                 return RC_ERROR;
//
//             root.bmFlag = BM_INVALID;
//             if (adfWriteRootBlock(vol,vol->rootBlock,&root)!=RC_OK)
//                 return RC_ERROR;
//
//             for(i=0; i<vol->bitmapSize; i++)
//                 if (vol->bitmapBlocksChg[i]) {
//                     if (adfWriteBitmapBlock(vol, vol->bitmapBlocks[i], vol->bitmapTable[i])!=RC_OK)
//                         return RC_ERROR;
//                     vol->bitmapBlocksChg[i] = FALSE;
//                 }
//
//             root.bmFlag = BM_VALID;
//             adfTime2AmigaTime(adfGiveCurrentTime(),&(root.days),&(root.mins),&(root.ticks));
//             if (adfWriteRootBlock(vol,vol->rootBlock,&root)!=RC_OK)
//                 return RC_ERROR;
//
//             return RC_OK;
         }
    }
}