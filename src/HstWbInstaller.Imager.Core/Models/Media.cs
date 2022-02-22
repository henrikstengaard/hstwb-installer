namespace HstWbInstaller.Imager.Core.Models
{
    using System;
    using System.IO;

    public class Media : IDisposable
    {
        private bool disposed;
        
        public enum MediaType
        {
            Raw,
            Vhd
        }

        public string Path;
        public string Model;
        public bool IsPhysicalDrive;
        public MediaType Type;

        public readonly Stream Stream;

        public Media(string path, string model, MediaType type, bool isPhysicalDrive, Stream stream)
        {
            Path = path;
            Model = model;
            Type = type;
            IsPhysicalDrive = isPhysicalDrive; 
            Stream = stream;
        }

        protected virtual void Dispose(bool disposing)
        {
            if (disposed)
            {
                return;
            }

            if (disposing)
            {
                Stream?.Dispose();
            }

            disposed = true;
        }

        public void Dispose() => Dispose(true);
    }
}