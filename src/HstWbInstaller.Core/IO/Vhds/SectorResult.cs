namespace HstWbInstaller.Core.IO.Vhds
{
    using System.Collections.Generic;
    using HstwbInstaller.Core;

    public class SectorResult
    {
        public int BytesRead { get; set; }
        public bool EndOfSectors { get; set; }
        public IEnumerable<Sector> Sectors { get; set; }
    }
}