namespace HstWbInstaller.Core.IO.FastFileSystem
{
    using System;

    public class CacheEntry
    {
//         struct CacheEntry{
//             int32_t header, size, protect;
//             short days, mins, ticks;
//             signed char type;
//             char nLen, cLen;
//             char name[MAXNAMELEN+1], comm[MAXCMMTLEN+1];
// /*    char *name, *comm;*/
//
//         };   
        public int Header;
        public int Size;
        public int Protect;
        public DateTime Date;
        public int Type;
        public string Name;
        public string Comment;

        public int EntryLen
        {
            get
            {
                var len = 24 + (Name ?? string.Empty).Length + 1 + (Comment ?? string.Empty).Length;
                return len % 2 == 0 ? len : len + 1;
            }
        }
    }
}