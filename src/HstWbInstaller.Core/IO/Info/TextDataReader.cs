namespace HstWbInstaller.Core.IO.Info
{
    using System.IO;
    using System.Threading.Tasks;
    using Extensions;

    public static class TextDataReader
    {
        public static async Task<TextData> Read(Stream stream)
        {
            var size = await stream.ReadUInt32();
            var text = await stream.ReadString((int)(size - 1));
            var zero = stream.ReadByte();

            if (zero != 0)
            {
                throw new IOException("Invalid zero byte");
            }

            return new TextData
            {
                Size = size,
                Text = text
            };
        }
    }
}