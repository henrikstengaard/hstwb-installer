namespace HstWbInstaller.Imager.Core.Models
{
    using System.Text.Json.Serialization;

    public class BlockDevice
    {
        [JsonPropertyName("path")]
        public string Path { get; set; }

        [JsonPropertyName("type")]
        public string Type { get; set; }

        [JsonPropertyName("name")]
        public string Name { get; set; }

        [JsonPropertyName("rm")]
        public bool Removable { get; set; }

        [JsonPropertyName("model")]
        public string Model { get; set; }

        [JsonPropertyName("size")]
        public long Size { get; set; }
        
        [JsonPropertyName("vendor")]
        public string Vendor { get; set; }
    }
}