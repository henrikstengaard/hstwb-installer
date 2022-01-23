namespace HstWbInstaller.Imager.Core.PhysicalDrives
{
    using System;
    using System.IO;
    using System.Threading;
    using System.Threading.Tasks;
    using Apis;
    using Microsoft.Win32.SafeHandles;

    public class WindowsPhysicalDriveStream : Stream
    {
        private readonly SafeFileHandle safeFileHandle;

        public WindowsPhysicalDriveStream(string path)
        {
            safeFileHandle = DeviceApi.CreateFile(path,
                DeviceApi.GENERIC_READ,
                DeviceApi.FILE_SHARE_READ | DeviceApi.FILE_SHARE_WRITE,
                IntPtr.Zero,
                DeviceApi.OPEN_EXISTING,
                DeviceApi.FILE_ATTRIBUTE_READONLY,
                IntPtr.Zero);
        }

        protected override void Dispose(bool disposing)
        {
            if (disposing)
            {
                safeFileHandle.Dispose();
                safeFileHandle.Close();
            }
            base.Dispose(disposing);
        }

        public override int Read(byte[] buffer, int offset, int count)
        {
            if (offset != 0)
            {
                throw new ArgumentException("'Only offset 0 is allow", nameof(offset));
            }
            
            if (!DeviceApi.ReadFile(safeFileHandle, buffer, Convert.ToUInt32(count), out var bytesRead, IntPtr.Zero))
            {
                throw new IOException($"ReadFile failed with bytes to read length {count}");
            }

            return Convert.ToInt32(bytesRead);
        }

        public override async Task<int> ReadAsync(byte[] buffer, int offset, int count, CancellationToken cancellationToken)
        {
            return await Task.Run(() => this.Read(buffer, offset, count), cancellationToken);
        }

        public override long Seek(long offset, SeekOrigin origin)
        {
            if (!Enum.TryParse<DeviceApi.EMoveMethod>(origin.ToString(), out var moveMethod))
            {
                throw new ArgumentOutOfRangeException(nameof(origin));
            }

            if (!DeviceApi.SetFilePointerEx(safeFileHandle, offset, out var newOffset, moveMethod))
            {
                throw new IOException($"SetFilePointerEx failed with offset {offset} and origin {origin}");
            }

            return newOffset;
        }

        public override void Write(byte[] buffer, int offset, int count)
        {
            if (!DeviceApi.WriteFile(safeFileHandle, buffer, Convert.ToUInt32(count), out _, IntPtr.Zero))
            {
                throw new IOException($"WriteFile failed with data length {count}");
            }
        }
        
        public override async Task WriteAsync(byte[] buffer, int offset, int count, CancellationToken cancellationToken)
        {
            await Task.Run(() => this.Write(buffer, offset, count), cancellationToken);
        }

        public override void Flush()
        {
        }

        public override void SetLength(long value) =>
            throw new NotSupportedException("Physical device doesn't support set length");

        public override bool CanRead => true;
        public override bool CanSeek => true;
        public override bool CanWrite => true;
        public override long Length => throw new NotSupportedException("Physical device doesn't support get length");
        public override long Position { get; set; }
    }
}