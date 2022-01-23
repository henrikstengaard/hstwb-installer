namespace HstWbInstaller.Imager.Core.Models
{
    using System.Collections.Generic;
    using System.Text.Json.Serialization;

    public class LsBlk
    {
        [JsonPropertyName("blockdevices")]
        public IEnumerable<BlockDevice> BlockDevices { get;set; }
    }
}