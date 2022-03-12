namespace HstWbInstaller.Imager.Core.Models
{
    using System.IO;
    using DiscUtils;

    public class VhdMedia : Media
    {
        private readonly VirtualDisk disk;
        private readonly Stream stream;

        public VhdMedia(string path, string model, long size, MediaType type, bool isPhysicalDrive, VirtualDisk disk, Stream stream = null) 
            : base(path, model, size, type, isPhysicalDrive, disk.Content)
        {
            this.disk = disk;
            this.stream = stream;
        }

        protected override void Dispose(bool disposing)
        {
            base.Dispose(disposing);
            if (disposing)
            {
                disk.Dispose();
                stream?.Close();
                stream?.Dispose();
            }
        }
    }
}