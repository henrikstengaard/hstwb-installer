namespace HstWbInstaller.Imager.Core.PhysicalDrives
{
    using System.IO;
    using HstWbInstaller.Core.IO;

    public class FakePhysicalDrive : GenericPhysicalDrive
    {
        private readonly long size;
        private readonly byte[] data;
        
        public FakePhysicalDrive(string path, string type, string model, long size) : base(path, type, model, size)
        {
            this.size = size;
            data = new byte[size];
        }

        public FakePhysicalDrive(string path, string type, string model, byte[] data) : base(path, type, model, data.Length)
        {
            this.size = data.Length;
            this.data = data;
        }
        
        public override Stream Open()
        {
            return new MemoryStream(data);
        }
    }
}