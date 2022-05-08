namespace HstWbInstaller.Core.IO.FastFileSystem
{
    using System;

    public static class Cache
    {
        public static void AdfAddInCache(Volume vol, EntryBlock parent, EntryBlock entry)
        {
            // https://github.com/lclevy/ADFlib/blob/be8a6f6e8d0ca8fda963803eef77366c7584649a/src/adf_cache.c#L354
            throw new NotImplementedException();
        }
        
        /*
 * adfUpdateCache
 *
 */
        public static void AdfUpdateCache(Volume vol, EntryBlock parent, EntryBlock entry, bool entryLenChg)
        {
            // https://github.com/lclevy/ADFlib/blob/be8a6f6e8d0ca8fda963803eef77366c7584649a/src/adf_cache.c#L441
            throw new NotImplementedException();
        }
    }
}