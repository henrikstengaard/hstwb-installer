namespace HstWbInstaller.Core.IO.FastFileSystem
{
    public static class Constants
    {
        public const int BitmapsPerLong = 8 * IO.Constants.LongSize;
        public const int MaxBitmapBlockPointersInRootBlock = 25;
        
/* ----- FILE SYSTEM ----- */

        public const int FSMASK_FFS = 1;
        public const int FSMASK_INTL = 2;
        public const int FSMASK_DIRCACHE = 4;


/* ----- ENTRIES ----- */

/* access constants */

        public const int ACCMASK_D = 1 << 0;
        public const int ACCMASK_E = 1 << 1;
        public const int ACCMASK_W = 1 << 2;
        public const int ACCMASK_R = 1 << 3;
        public const int ACCMASK_A = 1 << 4;
        public const int ACCMASK_P = 1 << 5;
        public const int ACCMASK_S = 1 << 6;
        public const int ACCMASK_H = 1 << 7;

        /* block constants */

        public const int BM_VALID = -1;
        public const int BM_INVALID = 0;

        public const int HT_SIZE = 72;
        public const int BM_SIZE = 25;
        public const int MAX_DATABLK = 72;

        public const int MAXNAMELEN = 30;
        public const int MAXCMMTLEN = 79;


        /* block primary and secondary types */

        public const int T_HEADER = 2;
        public const int ST_ROOT = 1;
        public const int ST_DIR = 2;
        public const int ST_FILE = -3;
        public const int ST_LFILE = -4;
        public const int ST_LDIR = 4;
        public const int ST_LSOFT = 3;
        public const int T_LIST = 16;
        public const int T_DATA = 8;
        public const int T_DIRC = 33;
    }
}