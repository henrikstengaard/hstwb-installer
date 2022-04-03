namespace HstWbInstaller.Core.IO.Lha
{
    public class Constants
    {
        public const byte EXTEND_GENERIC = 0;
        public const byte EXTEND_UNIX = (byte)'U';
        public const byte EXTEND_MSDOS = (byte)'M';
        public const byte EXTEND_MACOS = (byte)'m';
        public const byte EXTEND_OS9 = (byte)'9';
        public const byte EXTEND_OS2 = (byte)'2';
        public const byte EXTEND_OS68K = (byte)'K';
        public const byte EXTEND_OS386 = (byte)'3'; /* OS-9000??? */
        public const byte EXTEND_HUMAN = (byte)'H';
        public const byte EXTEND_CPM = (byte)'C';
        public const byte EXTEND_FLEX = (byte)'F';
        public const byte EXTEND_RUNSER = (byte)'R';
        public const byte EXTEND_AMIGA = (byte)'A';

        /* this OS type is not official */
        public const byte EXTEND_TOWNSOS = (byte)'T';
        public const byte EXTEND_XOSK = (byte)'X'; /* OS-9 for X68000 (?) */
        public const byte EXTEND_JAVA = (byte)'J';

        public const int UNIX_FILE_TYPEMASK = 0170000;
        public const int UNIX_FILE_REGULAR = 0100000;
        public const int UNIX_FILE_DIRECTORY = 0040000;
        public const int UNIX_FILE_SYMLINK = 0120000;
        public const int UNIX_SETUID = 0004000;
        public const int UNIX_SETGID = 0002000;
        public const int UNIX_STICKYBIT = 0001000;
        public const int UNIX_OWNER_READ_PERM = 0000400;
        public const int UNIX_OWNER_WRITE_PERM = 0000200;
        public const int UNIX_OWNER_EXEC_PERM = 0000100;
        public const int UNIX_GROUP_READ_PERM = 0000040;
        public const int UNIX_GROUP_WRITE_PERM = 0000020;
        public const int UNIX_GROUP_EXEC_PERM = 0000010;
        public const int UNIX_OTHER_READ_PERM = 0000004;
        public const int UNIX_OTHER_WRITE_PERM = 0000002;
        public const int UNIX_OTHER_EXEC_PERM = 0000001;
        public const int UNIX_RW_RW_RW = 0000666;

        public const string LZHUFF0_METHOD = "-lh0-";
        public const string LZHUFF1_METHOD = "-lh1-";
        public const string LZHUFF2_METHOD = "-lh2-";
        public const string LZHUFF3_METHOD = "-lh3-";
        public const string LZHUFF4_METHOD = "-lh4-";
        public const string LZHUFF5_METHOD = "-lh5-";
        public const string LZHUFF6_METHOD = "-lh6-";
        public const string LZHUFF7_METHOD = "-lh7-";
        public const string LARC_METHOD = "-lzs-";
        public const string LARC5_METHOD = "-lz5-";
        public const string LARC4_METHOD = "-lz4-";
        public const string LZHDIRS_METHOD = "-lhd-";
        public const string PMARC0_METHOD = "-pm0-";
        public const string PMARC2_METHOD = "-pm2-";
        
        public const int LZHUFF0_DICBIT = 0;      /* no compress */
        public const int LZHUFF1_DICBIT = 12;      /* 2^12 =  4KB sliding dictionary */
        public const int LZHUFF2_DICBIT = 13;      /* 2^13 =  8KB sliding dictionary */
        public const int LZHUFF3_DICBIT = 13;      /* 2^13 =  8KB sliding dictionary */
        public const int LZHUFF4_DICBIT = 12;      /* 2^12 =  4KB sliding dictionary */
        public const int LZHUFF5_DICBIT = 13;      /* 2^13 =  8KB sliding dictionary */
        public const int LZHUFF6_DICBIT = 15;      /* 2^15 = 32KB sliding dictionary */
        public const int LZHUFF7_DICBIT = 16;      /* 2^16 = 64KB sliding dictionary */
        public const int LARC_DICBIT = 11;      /* 2^11 =  2KB sliding dictionary */
        public const int LARC5_DICBIT = 12;      /* 2^12 =  4KB sliding dictionary */
        public const int LARC4_DICBIT = 0;      /* no compress */
        public const int PMARC0_DICBIT = 0;      /* no compress */
        public const int PMARC2_DICBIT = 13;      /* 2^13 =  8KB sliding dictionary */
        
//#ifdef SUPPORT_LH7
        public const int MAX_DICBIT = LZHUFF7_DICBIT; /* lh7 use 16bits */
// #endif
// #ifndef SUPPORT_LH7
// #define MAX_DICBIT LZHUFF6_DICBIT /* lh6 use 15bits */
// #endif

        public const int MAX_DICSIZ = (1 << MAX_DICBIT);

        public const byte UCHAR_MAX = (1<<8)-1;
        public const int CHAR_BIT = 8;
        
        /* slide.c */
        public const short MAXMATCH = 256; /* formerly F (not more than UCHAR_MAX + 1) */
        public const byte THRESHOLD = 3;   /* choose optimal value */

        public const byte USHRT_BIT = 16; /* (CHAR_BIT * sizeof(ushort)) */
        public const byte NP = (MAX_DICBIT + 1);
        public const byte NT = (USHRT_BIT + 3);
        public const short NC = UCHAR_MAX + MAXMATCH + 2 - THRESHOLD;

        public const byte PBIT = 5;       /* smallest integer such that (1 << PBIT) > * NP */
        public const byte TBIT = 5;       /* smallest integer such that (1 << TBIT) > * NT */
        public const byte CBIT = 9;       /* smallest integer such that (1 << CBIT) > * NC */ 
        
        /*      #if NT > NP #define NPT NT #else #define NPT NP #endif  */
        public const byte NPT = 0x80;


        public const int BUFFERSIZE = 2048;

        public const int LZHUFF0_METHOD_NUM = 0;
        public const int LZHUFF1_METHOD_NUM = 1;
        public const int LZHUFF2_METHOD_NUM = 2;
        public const int LZHUFF3_METHOD_NUM = 3;
        public const int LZHUFF4_METHOD_NUM = 4;
        public const int LZHUFF5_METHOD_NUM = 5;
        public const int LZHUFF6_METHOD_NUM = 6;
        public const int LZHUFF7_METHOD_NUM = 7;
        public const int LARC_METHOD_NUM = 8;
        public const int LARC5_METHOD_NUM = 9;
        public const int LARC4_METHOD_NUM = 10;
        public const int LZHDIRS_METHOD_NUM = 11;
        public const int PMARC0_METHOD_NUM = 12;
        public const int PMARC2_METHOD_NUM = 13;

        public const int EXTRABITS = 8;               /* >= log2(F-THRESHOLD+258-N1) */
        public const int BUFBITS = 16;              /* >= log2(MAXBUF) */
        public const int LENFIELD = 4;         /* bit size of length field for tree output */      
    }
}