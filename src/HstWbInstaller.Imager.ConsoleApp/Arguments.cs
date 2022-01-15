namespace HstWbInstaller.Imager.ConsoleApp
{
    public class Arguments
    {
        public enum CommandEnum
        {
            None,
            List,
            Info,
            Read,
            Write,
            Convert,
            Verify,
            Blank,
            Optimize
        }
        
        public CommandEnum Command;
        public string Src;
        public string Dest;
        public bool Fake;
    }
}