namespace HstWbInstaller.Imager.ConsoleApp.Models
{
    public class WmicDiskDrive
    {
        public string MediaType { get; set; }
        public string Model { get; set; }
        public string Name { get; set; }
        public ulong Size { get; set; }
        public string InterfaceType { get; set; }
    }
}