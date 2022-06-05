namespace HstWbInstaller.Core.IO.Info
{
    public static class Constants
    {
        public static class DiskObjectTypes
        {
            public const int DISK = 1;                 // a disk
            public const int DRAWER = 2;               // a directory
            public const int TOOL = 3;                  // a program
            public const int PROJECT = 4;               // a project file with defined program to start
            public const int GARBAGE = 5;               // the trashcan
            public const int DEVICE = 6;                // should never appear
            public const int KICK = 7;                  // a kickstart disk
            public const int APP_ICON = 8; // should never appear
        }

        public const int BITS_PER_BYTE = 8;

        public static class NewIcon
        {
            public const string Header = "*** DON'T EDIT THE FOLLOWING LINES!! ***";
        }
    }
}