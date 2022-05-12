namespace HstWbInstaller.Core.IO.FastFileSystem
{
    using System;
    using System.IO;
    using System.Text;
    using System.Threading.Tasks;

    public static class Cache
    {
        private static readonly Encoding iso88591Encoding = Encoding.GetEncoding("ISO-8859-1"); 
        
        public static async Task AdfAddInCache(Volume vol, EntryBlock parent, EntryBlock entry)
        {
//             // https://github.com/lclevy/ADFlib/blob/be8a6f6e8d0ca8fda963803eef77366c7584649a/src/adf_cache.c#L354

            DirCacheBlock dirc, newDirc;
            CacheEntry caEntry;
    // struct bDirCacheBlock dirc, newDirc;
    // SECTNUM nSect, nCache;
    // struct CacheEntry caEntry, newEntry;
    // int offset, n;
    // int entryLen;

    var newEntry = AdfEntry2CacheEntry(entry);
    var entryLen = newEntry.EntryLen;
/*printf("adfAddInCache--%4ld %2d %6ld %8lx %4d %2d:%02d:%02d %30s %22s\n",
    newEntry.header, newEntry.type, newEntry.size, newEntry.protect,
    newEntry.days, newEntry.mins/60, newEntry.mins%60, 
	newEntry.ticks/50,
	newEntry.name, newEntry.comm);
*/
            var offset = 0;
            var n = 0;
            var nCache = 0;
    var nSect = parent.Extension;
    do
    {
        dirc = await AdfReadDirCBlock(vol, nSect);
        offset = 0; n = 0;
/*printf("parent=%4ld\n",dirc.parent);*/
        while(n < dirc.RecordsNb) 
        {
            caEntry = AdfGetCacheEntry(dirc, ref offset);
/*printf("*%4ld %2d %6ld %8lx %4d %2d:%02d:%02d %30s %22s\n",
    caEntry.header, caEntry.type, caEntry.size, caEntry.protect,
    caEntry.days, caEntry.mins/60, caEntry.mins%60, 
	caEntry.ticks/50,
	caEntry.name, caEntry.comm);
*/
            n++;
        }
        
/*        if (offset+entryLen<=488) {
            adfPutCacheEntry(&dirc, &offset, &newEntry);
            dirc.recordsNb++;
            adfWriteDirCBlock(vol, dirc.headerKey, &dirc);
            return rc;
        }*/
        nSect = dirc.NextDirC;
    }while(nSect!=0);
    
    /* in the last block */
    if (offset + entryLen <= 488) {
        AdfPutCacheEntry(dirc, ref offset, newEntry);
        dirc.RecordsNb++;
/*printf("entry name=%s\n",newEntry.name);*/
    }
    else {
        /* request one new block free */
        nCache = Bitmap.AdfGet1FreeBlock(vol);
        if (nCache==-1) 
        {
           throw new IOException("adfCreateDir : nCache==-1");
        }

        newDirc = new DirCacheBlock();
        /* create a new dircache block */
        //memset(&newDirc,0,512);
        if (parent.SecType==Constants.ST_ROOT)
            newDirc.Parent = vol.RootBlock.HeaderKey;
        else if (parent.SecType==Constants.ST_DIR)
            newDirc.Parent = parent.HeaderKey;
        else
            throw new IOException("adfAddInCache : unknown secType");
        newDirc.RecordsNb = 0;
        newDirc.NextDirC = 0;

        AdfPutCacheEntry(dirc, ref offset, newEntry);
        newDirc.RecordsNb++;
        await AdfWriteDirCBlock(vol, nCache, newDirc);
        dirc.NextDirC = nCache;
    }
/*printf("dirc.headerKey=%ld\n",dirc.headerKey);*/
            await AdfWriteDirCBlock(vol, dirc.HeaderKey, dirc);
/*if (strcmp(entry->name,"file_5u")==0)
dumpBlock(&dirc);
*/
        }
        
/*
 * adfEntry2CacheEntry
 *
 * converts one dir entry into a cache entry, and return its future length in records[]
 */
        public static CacheEntry AdfEntry2CacheEntry(EntryBlock entry)
        {
            return new CacheEntry
            {
                Header = entry.HeaderKey,
                Size = entry.SecType == Constants.ST_FILE ? entry.ByteSize : 0,
                Protect = entry.Access,
                Date = entry.Date,
                Type = entry.SecType,
                Name = entry.Name,
                Comment = entry.Comment
            };
            
            /* new entry */
            // newEntry->header = entry->headerKey;
            // if (entry->secType==ST_FILE)
            //     newEntry->size = entry->byteSize;
            // else
            //     newEntry->size = 0L;
            // newEntry->protect = entry->access;
            // newEntry->days = (short)entry->days;
            // newEntry->mins = (short)entry->mins;
            // newEntry->ticks  = (short)entry->ticks;
            // newEntry->type = (signed char)entry->secType;
            // newEntry->nLen = entry->nameLen;
            // memcpy(newEntry->name, entry->name, newEntry->nLen);
            // newEntry->name[(int)(newEntry->nLen)] = '\0';
            // newEntry->cLen = entry->commLen;
            // if (newEntry->cLen>0)
            //     memcpy(newEntry->comm, entry->comment, newEntry->cLen);
            //
            // entryLen = 24+newEntry->nLen+1+newEntry->cLen;

/*printf("entry->name %d entry->comment %d\n",entry->nameLen,entry->commLen);
printf("newEntry->nLen %d newEntry->cLen %d\n",newEntry->nLen,newEntry->cLen);
*/
            // if ((entryLen%2)==0)
            //     return entryLen;
            // else
            //     return entryLen+1;
        }        
        
        /*
 * adfUpdateCache
 *
 */
        public static async Task AdfUpdateCache(Volume vol, EntryBlock parent, EntryBlock entry, bool entryLenChg)
        {
            // https://github.com/lclevy/ADFlib/blob/be8a6f6e8d0ca8fda963803eef77366c7584649a/src/adf_cache.c#L441
            throw new NotImplementedException();
        }
        
/*
 * adfCreateEmptyCache
 *
 */
        public static async Task AdfCreateEmptyCache(Volume vol, EntryBlock parent, int nSect)
        {
            // struct bDirCacheBlock dirc;
            int nCache;

            if (nSect==-1) {
                nCache = Bitmap.AdfGet1FreeBlock(vol);
                if (nCache==-1) {
                    throw new IOException("adfCreateDir : nCache==-1");
                }
            }
            else
                nCache = nSect;

            if (parent.Extension==0)
                parent.Extension = nCache;

            var dirc = new DirCacheBlock();
            //memset(&dirc,0, sizeof(struct bDirCacheBlock));

            if (parent.SecType == Constants.ST_ROOT)
                dirc.Parent = vol.RootBlock.HeaderKey;
            else if (parent.SecType == Constants.ST_DIR)
                dirc.Parent = parent.HeaderKey;
            else {
                throw new IOException("adfCreateEmptyCache : unknown secType");
/*printf("secType=%ld\n",parent->secType);*/
            }
        
            dirc.RecordsNb = 0;
            dirc.NextDirC = 0;

            await AdfWriteDirCBlock(vol, nCache, dirc);
        }
        
        
/*
 * adfReadDirCBlock
 *
 */
        public static async Task<DirCacheBlock> AdfReadDirCBlock(Volume vol, int nSect)
        {
            var buf = await Disk.AdfReadBlock(vol, nSect);

//             memcpy(dirc,buf,512);
// #ifdef LITT_ENDIAN
//             swapEndian((uint8_t*)dirc,SWBL_CACHE);
// #endif
            var dirc = await DirCacheBlockReader.Parse(buf);

            if (dirc.CheckSum != Raw.AdfNormalSum(buf, 20, buf.Length))
            {
                throw new IOException("adfReadDirCBlock : invalid checksum");
            }
            if (dirc.Type != Constants.T_DIRC)
                throw new IOException("adfReadDirCBlock : T_DIRC not found");
            if (dirc.HeaderKey != nSect)
                throw new IOException("adfReadDirCBlock : headerKey!=nSect");

            return dirc;
        }        
/*
 * adfWriteDirCblock
 *
 */
        public static async Task AdfWriteDirCBlock(Volume vol, int nSect, DirCacheBlock dirc)
        {
            // uint8_t buf[LOGICAL_BLOCK_SIZE];
            // uint32_t newSum;
 
            dirc.Type = Constants.T_DIRC;
            dirc.HeaderKey = nSect; 

//             memcpy(buf, dirc, LOGICAL_BLOCK_SIZE);
// #ifdef LITT_ENDIAN
//             swapEndian(buf, SWBL_CACHE);
// #endif
//
//             newSum = adfNormalSum(buf, 20, LOGICAL_BLOCK_SIZE);
//             swLong(buf+20,newSum);
/*    *(int32_t*)(buf+20) = swapLong((uint8_t*)&newSum);*/

            var buf = await DirCacheBlockWriter.BuildBlock(dirc, vol.BlockSize);

            await Disk.AdfWriteBlock(vol, nSect, buf);
/*puts("adfWriteDirCBlock");*/
        }    
        
/*
 * adfGetCacheEntry
 *
 * Returns a cache entry, starting from the offset p (the index into records[])
 * This offset is updated to the end of the returned entry.
 */
        public static CacheEntry AdfGetCacheEntry(DirCacheBlock dirc, ref int ptr)
        {
            // int ptr;
            //
            // ptr = *p;

/*printf("p=%d\n",ptr);*/

// #ifdef LITT_ENDIAN
//             cEntry->header = swapLong(dirc->records+ptr);
//             cEntry->size = swapLong(dirc->records+ptr+4);
//             cEntry->protect = swapLong(dirc->records+ptr+8);
//             cEntry->days = swapShort(dirc->records+ptr+16);
//             cEntry->mins = swapShort(dirc->records+ptr+18);
//             cEntry->ticks = swapShort(dirc->records+ptr+20);
// #else
             var cEntry = new CacheEntry
             {
                 Header = BigEndianConverter.ConvertBytesToInt32(dirc.Records, ptr),
                 Size = BigEndianConverter.ConvertBytesToInt32(dirc.Records, ptr + 4),
                 Protect = BigEndianConverter.ConvertBytesToInt32(dirc.Records, ptr + 8)
             };
             var days = BigEndianConverter.ConvertBytesToInt16(dirc.Records, ptr + 16);
             var minutes = BigEndianConverter.ConvertBytesToInt16(dirc.Records, ptr + 18);
             var ticks = BigEndianConverter.ConvertBytesToInt16(dirc.Records, ptr + 20);
             cEntry.Date = DateHelper.ConvertToDate(days, minutes, ticks);
             cEntry.Type = dirc.Records[ptr+22];
             
             var nLen = dirc.Records[ptr+23];
             cEntry.Name = iso88591Encoding.GetString(dirc.Records, ptr + 24, nLen); 
             var cLen = dirc.Records[ptr + 24 + nLen];
             cEntry.Comment = iso88591Encoding.GetString(dirc.Records, dirc.Records[ptr + 24 + nLen + 1], nLen); 
             
             var p = ptr + 24 + nLen + 1 + cLen;
             
             if (p % 2 != 0)
                 p = p + 1;

             ptr = p;
// // #endif
//             cEntry->type =(signed char) dirc->records[ptr+22];
//
//             cEntry->nLen = dirc->records[ptr+23];
// /*    cEntry->name = (char*)malloc(sizeof(char)*(cEntry->nLen+1));
//     if (!cEntry->name)
//          return;
// */    memcpy(cEntry->name, dirc->records+ptr+24, cEntry->nLen);
//             cEntry->name[(int)(cEntry->nLen)]='\0';
//
//             cEntry->cLen = dirc->records[ptr+24+cEntry->nLen];
//             if (cEntry->cLen>0) {
// /*        cEntry->comm =(char*)malloc(sizeof(char)*(cEntry->cLen+1));
//         if (!cEntry->comm) {
//             free( cEntry->name ); cEntry->name=NULL;
//             return;
//         }
// */        memcpy(cEntry->comm,dirc->records+ptr+24+cEntry->nLen+1,cEntry->cLen);
//             }
//             cEntry->comm[(int)(cEntry->cLen)]='\0';
// /*printf("cEntry->nLen %d cEntry->cLen %d %s\n",cEntry->nLen,cEntry->cLen,cEntry->name);*/
//             *p  = ptr+24+cEntry->nLen+1+cEntry->cLen;
//
//             /* the starting offset of each record must be even (68000 constraint) */ 
//             if ((*p%2)!=0)
//                 *p=(*p)+1;
            return cEntry;
        }      
        
        /*
 * adfPutCacheEntry
 *
 * remplaces one cache entry at the p offset, and returns its length
 */
        public static int AdfPutCacheEntry(DirCacheBlock dirc, ref int ptr, CacheEntry cEntry)
        {
//             int ptr, l;
//             ptr = *p;
//
// #ifdef LITT_ENDIAN
//             swLong(dirc->records+ptr, cEntry->header);
//             swLong(dirc->records+ptr+4, cEntry->size);
//             swLong(dirc->records+ptr+8, cEntry->protect);
//             swShort(dirc->records+ptr+16, cEntry->days);
//             swShort(dirc->records+ptr+18, cEntry->mins);
//             swShort(dirc->records+ptr+20, cEntry->ticks);
// #else
            BigEndianConverter.ConvertInt32ToBytes(cEntry.Header, dirc.Records, ptr);
            BigEndianConverter.ConvertInt32ToBytes(cEntry.Size, dirc.Records, ptr + 4);
            BigEndianConverter.ConvertInt32ToBytes(cEntry.Protect, dirc.Records, ptr + 8);
            var amigaDate = DateHelper.ConvertToAmigaDate(cEntry.Date);
            BigEndianConverter.ConvertInt16ToBytes((short)amigaDate.Days, dirc.Records, ptr + 16);
            BigEndianConverter.ConvertInt16ToBytes((short)amigaDate.Minutes, dirc.Records, ptr + 18);
            BigEndianConverter.ConvertInt16ToBytes((short)amigaDate.Ticks, dirc.Records, ptr + 20);
            
            // memcpy(dirc->records+ptr,&(cEntry->header),4);
            // memcpy(dirc->records+ptr+4,&(cEntry->size),4);
            // memcpy(dirc->records+ptr+8,&(cEntry->protect),4);
            // memcpy(dirc->records+ptr+16,&(cEntry->days),2);
            // memcpy(dirc->records+ptr+18,&(cEntry->mins),2);
            // memcpy(dirc->records+ptr+20,&(cEntry->ticks),2);
// #endif
            dirc.Records[ptr + 22] = (byte)cEntry.Type;

            var nameBytes = iso88591Encoding.GetBytes(cEntry.Name);
            dirc.Records[ptr + 23] = (byte)nameBytes.Length;
            Array.Copy(nameBytes, 0, dirc.Records, ptr + 24, nameBytes.Length);

            var commentBytes = iso88591Encoding.GetBytes(cEntry.Comment);
            dirc.Records[ptr + 24 + nameBytes.Length] = (byte)commentBytes.Length;
            Array.Copy(commentBytes, 0, dirc.Records, ptr + 24, commentBytes.Length + 1);

/*puts("adfPutCacheEntry");*/

            var l = 25 + nameBytes.Length + commentBytes.Length;
            if (l % 2==0)
                return l;
            else {
                dirc.Records[ptr+l] = 0;
                return l + 1;
            }

            /* ptr%2 must be == 0, if l%2==0, (ptr+l)%2==0 */ 
        }
    }
}