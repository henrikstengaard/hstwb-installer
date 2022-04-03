namespace HstWbInstaller.Core.IO.Lha
{
    public class Lha
    {
        // https://github.com/jca02266/lha/blob/03475355bc6311f7f816ea9a88fb34a0029d975b/src/lha.h
        // for globals
        
        public short dicbit;
        public long origsize, compsize;
        public bool ignoreDirectory;
        public bool verifyMode;
        public bool textMode;
        public bool extract_broken_archive;

        public Lha()
        {
            ignoreDirectory = true;
            verifyMode = false;
            textMode = false;
            extract_broken_archive = false;
        }
    }
}