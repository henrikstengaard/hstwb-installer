namespace HstWbInstaller.Core.IO.Vhds
{
    public class Sector
    {
        public long Start { get; set; }
        public long End { get; set; }
        public long Size { get; set; }
        public bool IsZeroFilled { get; set; }
        public byte[] Data { get; set; }
    }
}