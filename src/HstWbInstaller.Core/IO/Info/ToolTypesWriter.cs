namespace HstWbInstaller.Core.IO.Info
{
    using System.IO;
    using System.Linq;
    using System.Threading.Tasks;
    using Extensions;

    public static class ToolTypesWriter
    {
        public static async Task Write(ToolTypes toolTypes, Stream stream)
        {
            var textDatas = toolTypes.TextDatas.ToList();
            var entries = (textDatas.Count + 1) * 4;

            await stream.WriteLittleEndianUInt32((uint)entries);
            
            foreach (var textData in textDatas)
            {
                await TextDataWriter.Write(textData, stream);
            }
        }
    }
}