namespace HstWbInstaller.Imager.Core.PhysicalDrives
{
    using System;
    using System.Text.Json;
    using Models;

    public static class LsBlkReader
    {
        public static LsBlk ParseLsBlk(string json)
        {
            var lsBlk = JsonSerializer.Deserialize<LsBlk>(json);

            if (lsBlk == null)
            {
                throw new ArgumentException("Invalid lsblk json", nameof(json));
            }

            return lsBlk;
        }
    }
}