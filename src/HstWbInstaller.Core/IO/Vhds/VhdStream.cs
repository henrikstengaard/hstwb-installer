namespace HstWbInstaller.Core.IO.Vhds
{
    using System.IO;
    using DiscUtils;
    using DiscUtils.Streams;
    using DiscUtils.Vhd;
    
    public class VhdStream : Stream
    {
        private readonly Stream stream;
        private readonly Disk vhdDisk;
        
        public VhdStream(string path, long size)
        {
            stream = File.Open(path, FileMode.Create, FileAccess.ReadWrite);
            vhdDisk = Disk.InitializeDynamic(stream, Ownership.None, size);
        }
        
        public override void Flush()
        {
            stream.Flush();
        }

        public override int Read(byte[] buffer, int offset, int count)
        {
            return vhdDisk.Content.Read(buffer, 0, count);
        }

        public override long Seek(long offset, SeekOrigin origin)
        {
            return vhdDisk.Content.Seek(offset, origin);
        }

        public override void SetLength(long value)
        {
        }

        public override void Write(byte[] buffer, int offset, int count)
        {
            stream.Write(buffer, offset, count);
        }

        public override bool CanRead { get; }
        public override bool CanSeek { get; }
        public override bool CanWrite { get; }
        public override long Length { get; }
        public override long Position { get; set; }
    }
}