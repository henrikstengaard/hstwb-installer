namespace HstWbInstaller.Core.IO.Lha
{
    using System.IO;
    using System.Text;
    using System.Threading.Tasks;

    public class LhaReader
    {
        private readonly Stream stream;
        private readonly Encoding encoding;
        private LzHeader current;

        public LhaReader(Stream stream, Encoding encoding)
        {
            this.stream = stream;
            this.encoding = encoding;
            this.current = null;
        }

        public async Task<LzHeader> Read()
        {
            if (current != null)
            {
                stream.Seek(current.HeaderOffset + current.HeaderSize + current.PackedSize, SeekOrigin.Begin);
            }

            current = await LhaHeaderReader.GetHeader(stream, encoding);
            return current;
        }
    }
}