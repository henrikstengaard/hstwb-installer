namespace HstWbInstaller.Imager.GuiApp.Models
{
    public class FileSystemHeaderBlockViewModel
    {
        public byte[] DosType { get; set; }
        public string DosTypeFormatted { get; set; }
        public string DosTypeHex { get; set; }

        public uint Version { get; set; }
        public uint MajorVersion { get; set; }
        public uint MinorVersion { get; set; }
    }
}