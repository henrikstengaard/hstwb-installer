namespace HstWbInstaller.Imager.Core.Models
{
    public class WmicDiskDrive
    {
        public string MediaType { get; set; }
        public string Model { get; set; }
        public string Name { get; set; }
        public long? Size { get; set; }
        public string InterfaceType { get; set; }
    }
}