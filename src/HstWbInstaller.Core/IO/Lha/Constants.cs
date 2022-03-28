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
    }
}