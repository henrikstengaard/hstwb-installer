namespace HstWbInstaller.Imager.ConsoleApp.PhysicalDrives
{
    using System;
    using System.IO;

    public class FakePhysicalDrive : GenericPhysicalDrive
    {
        public FakePhysicalDrive(string path, string type, string model, long size) : base(path, type, model, size)
        {
        }

        public override Stream Open()
        {
            throw new NotSupportedException();
        }
    }
}