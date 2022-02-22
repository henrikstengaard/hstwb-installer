namespace HstWbInstaller.Imager.GuiApp.Models
{
    public class FileSystemHeaderBlockViewModel
    {
        public int Size { get; set; }
        public byte[] DosType { get; set; }
        public string DosTypeFormatted { get; set; }
        public string DosTypeHex { get; set; }
        public uint Version { get; set; }
        public string VersionFormatted { get; set; }
        public string FileSystemName { get; set; }
    }
}