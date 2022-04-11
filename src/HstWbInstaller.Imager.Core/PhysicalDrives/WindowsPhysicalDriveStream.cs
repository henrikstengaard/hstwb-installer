namespace HstWbInstaller.Imager.Core.PhysicalDrives
{
    using System;
    using System.IO;
    using Apis;

    public class WindowsPhysicalDriveStream : Stream
    {
        // private const int BLOCK_SIZE = 16384; //512;
        // private readonly SafeFileHandle safeFileHandle;
        private readonly Win32RawDisk win32RawDisk;

        public WindowsPhysicalDriveStream(string path, long size, bool writable)
        {
            this.CanWrite = writable;
            this.win32RawDisk = new Win32RawDisk(path, size, writable);
        }

        protected override void Dispose(bool disposing)
        {
            if (disposing)
            {
                win32RawDisk.Dispose();
            }

            base.Dispose(disposing);
        }

        public override int Read(byte[] buffer, int offset, int count)
        {
            if (offset != 0)
            {
                throw new ArgumentException("'Only offset 0 is allow", nameof(offset));
            }
            
            return Convert.ToInt32(win32RawDisk.Read(buffer));
        }

        public override long Seek(long offset, SeekOrigin origin)
        {
            return win32RawDisk.Seek(offset, origin);
        }

        public override void Write(byte[] buffer, int offset, int count)
        {
            if (offset != 0)
            {
                throw new ArgumentException("Only offset 0 is allow", nameof(offset));
            }

            win32RawDisk.Write(buffer);
        }

        public override void Flush()
        {
        }

        public override void SetLength(long value) =>
            throw new NotSupportedException("Physical device doesn't support set length");

        public override bool CanRead => true;
        public override bool CanSeek => true;
        public override bool CanWrite { get; }

        public override long Length => win32RawDisk.Size();

        public override long Position
        {
            get => win32RawDisk.Position();
            set => win32RawDisk.Seek(value, SeekOrigin.Begin);
        } 
    }
}