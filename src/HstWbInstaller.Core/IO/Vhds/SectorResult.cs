namespace HstWbInstaller.Core.IO.Vhds
{
    using System.Collections.Generic;
    using HstwbInstaller.Core;

    public class SectorResult
    {
        public bool EndOfSectors { get; set; }
        public IEnumerable<Sector> Sectors { get; set; }
    }
}