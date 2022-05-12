namespace HstWbInstaller.Core.IO.FastFileSystem
{
    public static class Macro
    {
        public static bool isFFS(int c) => (c& Constants.FSMASK_FFS) != 0;
        public static bool isOFS(int c) => (c & Constants.FSMASK_FFS) == 0;
        public static bool isINTL(int c) => (c & Constants.FSMASK_INTL) != 0;
        public static bool isDIRCACHE(int c) => (c & Constants.FSMASK_DIRCACHE) != 0;

        public static bool hasD(int c) => (c & Constants.ACCMASK_D) != 0;
        public static bool hasE(int c) => (c & Constants.ACCMASK_E) != 0;
        public static bool hasW(int c) => (c&Constants.ACCMASK_W) != 0;
        public static bool hasR(int c) => (c&Constants.ACCMASK_R) != 0;
        public static bool hasA(int c) => (c&Constants.ACCMASK_A) != 0;
        public static bool hasP(int c) => (c&Constants.ACCMASK_P) != 0;
        public static bool hasS(int c) => (c&Constants.ACCMASK_S) != 0;
        public static bool hasH(int c) => (c&Constants.ACCMASK_H) != 0;
    }
}