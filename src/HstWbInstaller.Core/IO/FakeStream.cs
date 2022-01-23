namespace HstWbInstaller.Core.IO
{
    using System;
    using System.IO;

    public class FakeStream : Stream
    {
        private long size;
        private long fakeOffset;

        public FakeStream(long size)
        {
            this.size = size;
            this.fakeOffset = 0;
        }
        
        public override void Flush()
        {
        }

        public override int Read(byte[] buffer, int offset, int count)
        {
            if (fakeOffset >= size || count == 0)
            {
                return 0;
            }
            
            var bytesRead = fakeOffset + count > size ? size - fakeOffset : count; 
            
            for (var i = 0; i < bytesRead; i++)
            {
                buffer[offset + i] = (byte)(fakeOffset + i > 1000000 ? 0 : 1);
            }

            this.fakeOffset += bytesRead;

            return Convert.ToInt32(bytesRead);
        }

        public override long Seek(long offset, SeekOrigin origin)
        {
            this.fakeOffset = offset;
            return this.fakeOffset;
        }

        public override void SetLength(long value)
        {
            size = value;
        }

        public override void Write(byte[] buffer, int offset, int count)
        {
        }

        public override bool CanRead => true;
        public override bool CanSeek => true;
        public override bool CanWrite => true;
        public override long Length => size;

        public override long Position
        {
            get => fakeOffset;
            set => fakeOffset = value;
        }
    }
}