namespace HstWbInstaller.Imager.Core.Models
{
    using System.Collections.Generic;

    public class DiskUtilInfo
    {
        public string BusProtocol { get; set; }
        public string IoRegistryEntryName { get; set; }
        public long Size { get; set; }
        public string DeviceNode { get; set; }
        public string MediaType { get; set; }
    }

    public class DiskUtilDisk
    {
        public string DeviceIdentifier { get; set; }
        public long Size { get; set; }
        public IEnumerable<DiskUtilPartition> Partitions { get; set; }

        public DiskUtilDisk()
        {
            Partitions = new List<DiskUtilPartition>();
        }
    }
}