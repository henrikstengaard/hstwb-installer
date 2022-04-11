namespace HstWbInstaller.Core.IO.Pfs3
{
    public class ListType
    {
        // union listtype
        // {
        // 	struct
        // 	{
        // 		unsigned pad:11;
        // 		unsigned dir:1;     // 0 = file; 1 = dir or volume
        // 		unsigned type:2;    // 0 = unknown; 3 = lock; 1 = volume; 2 = fileentry
        // 		unsigned access:2;  // 0 = read shared; 2 = read excl; 1,3 = write shared, excl
        // 	} flags;
        //
        // 	UWORD value;
        // };

        public enum ListTypeDir
        {
            File,
            Dir
        }

        public enum ListTypeAccess
        {
            // unsigned access:2;  // 0 = read shared; 2 = read excl; 1,3 = write shared, excl
            ReadShared,
            WriteShared,
            ReadExcl,
            WriteExcl
        }

        public enum ListTypeType
        {
            // unsigned type:2;    // 0 = unknown; 3 = lock; 1 = volume; 2 = fileentry
            Unknown,
            Volume,
            FileEntry,
            Lock
        }
        
        public ListTypeDir dir { get; set; }
        public ListTypeType type { get; set; }
        public ListTypeAccess access { get; set; }
    }
}