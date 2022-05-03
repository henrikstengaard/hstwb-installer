namespace HstWbInstaller.Core.IO.Pfs3.Blocks
{
    using System.IO;
    using System.Threading.Tasks;
    using Extensions;

    public static class DirEntryReader
    {
        public static async Task<direntry> Read(Stream stream)
        {
            return new direntry
            {
                next = (byte)stream.ReadByte(),
                type = (byte)stream.ReadByte(),
                anode = await stream.ReadUInt32(),
                fsize = await stream.ReadUInt32(),
                CreationDate = await DateHelper.ReadDate(stream),
                protection = (byte)stream.ReadByte(),
                nlength = (byte)stream.ReadByte(),
                startofname = (byte)stream.ReadByte(),
                pad = (byte)stream.ReadByte()
            };
        }
    }
}