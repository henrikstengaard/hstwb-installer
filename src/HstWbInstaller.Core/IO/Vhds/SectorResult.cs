namespace HstWbInstaller.Core.IO.Vhds
{
    using System.Collections.Generic;

    public class SectorResult
    {
        public long Start { get; set; }
        public long End { get; set; }
        public int BytesRead { get; set; }
        public bool EndOfSectors { get; set; }
        public IEnumerable<Sector> Sectors { get; set; }
        public byte[] Data { get; set; }
    }
}