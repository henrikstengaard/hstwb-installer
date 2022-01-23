namespace HstWbInstaller.Imager.Core
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

        public CommandEnum Command { get; set; }
        public string SourcePath { get; set; }
        public string DestinationPath { get; set; }
        public long? Size { get; set; }
        public bool Fake { get; set; }
    }
}