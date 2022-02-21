namespace HstWbInstaller.Imager.GuiApp.Models
{
    public class PartitionBlockViewModel
    {
        public string DriveName { get; set; }
        public uint SizeOfVector { get; set; }
        public uint SizeBlock { get; set; }
        public uint Surfaces { get; set; }
        public uint Sectors { get; set; }
        public uint BlocksPerTrack { get; set; }
        public uint Reserved { get; set; }
        public uint PreAlloc { get; set; }
        public uint LowCyl { get; set; }
        public uint HighCyl { get; set; }
        public uint NumBuffer { get; set; }
        
        public uint MaxTransfer { get; set; }
        public string MaxTransferHex { get; set; }

        public uint Mask { get; set; }
        public string MaskHex { get; set; }
        
        public uint BootPriority { get; set; }
        public byte[] DosType { get; set; }
        public string DosTypeFormatted { get; set; }
        public string DosTypeHex { get; set; }
        
        public long PartitionSize { get; set; }
        public uint FileSystemBlockSize { get; set; }
        public bool Bootable { get; set; }
        public bool NoMount { get; set; }
    }
}