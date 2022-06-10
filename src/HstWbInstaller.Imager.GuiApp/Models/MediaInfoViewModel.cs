namespace HstWbInstaller.Imager.GuiApp.Models
{
    public class MediaInfoViewModel
    {
        public string Path { get; set; }
        public string Model { get; set; }
        public bool IsPhysicalDrive;
        public long DiskSize { get; set; }
        public RigidDiskBlockViewModel RigidDiskBlock { get; set; }
    }
}