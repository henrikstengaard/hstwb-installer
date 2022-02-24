namespace HstWbInstaller.Imager.Core.PhysicalDrives
{
    using System;
    using System.IO;
    using Apis;

    public class WindowsPhysicalDriveStream : Stream
    {
        private readonly bool writable;
        // private const int BLOCK_SIZE = 16384; //512;
        // private readonly SafeFileHandle safeFileHandle;
        private readonly Win32RawDisk win32RawDisk;

        public WindowsPhysicalDriveStream(string path, long size, bool writable)
        {
            this.writable = writable;
            this.Length = size;
            this.win32RawDisk = new Win32RawDisk(path, writable);
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

        // public override async Task<int> ReadAsync(byte[] buffer, int offset, int count,
        //     CancellationToken cancellationToken)
        // {
        //     return await Task.Run(() => this.Read(buffer, offset, count), cancellationToken);
        // }

        public override long Seek(long offset, SeekOrigin origin)
        {
            return win32RawDisk.Seek(offset, origin);
        }

        public override void Write(byte[] buffer, int offset, int count)
        {
            if (offset != 0)
            {
                throw new ArgumentException("'Only offset 0 is allow", nameof(offset));
            }

            win32RawDisk.Write(buffer);
            
            // var bufferOffset = 0;
            // do
            // {
            //     var blockSize = Math.Min(count - bufferOffset, BLOCK_SIZE);
            //     var block = new byte[blockSize];
            //     Array.Copy(buffer, bufferOffset, block, 0, blockSize);
            //     if (!DeviceApi.WriteFile(safeFileHandle, block, Convert.ToUInt32(blockSize), out var bytesWritten,
            //             IntPtr.Zero))
            //     {
            //         int error = Marshal.GetLastWin32Error();
            //         throw new IOException($"WriteFile failed with data length {count}");
            //     }
            //
            //     bufferOffset += blockSize;
            //     Seek(blockSize, SeekOrigin.Current);
            // } while (bufferOffset < count);
        }

        // public override async Task WriteAsync(byte[] buffer, int offset, int count, CancellationToken cancellationToken)
        // {
        //     await Task.Run(() => this.Write(buffer, offset, count), cancellationToken);
        // }

        public override void Flush()
        {
        }

        public override void SetLength(long value) =>
            throw new NotSupportedException("Physical device doesn't support set length");

        public override bool CanRead => true;
        public override bool CanSeek => true;
        public override bool CanWrite => true;
        public override long Length { get; }
        public override long Position { get; set; }
    }
}