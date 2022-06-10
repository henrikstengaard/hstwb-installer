namespace HstWbInstaller.Core.IO.Info
{
    using System.Collections.Generic;
    using System.IO;
    using System.Threading.Tasks;
    using Extensions;

    public static class ToolTypesReader
    {
        public static async Task<ToolTypes> Read(Stream stream)
        {
            var entries = await stream.ReadUInt32();
            var count = (entries / 4) - 1;

            var textDatas = new List<TextData>();
            for (var i = 0; i < count; i++)
            {
                textDatas.Add(await TextDataReader.Read(stream));
            }

            return new ToolTypes
            {
                TextDatas = textDatas
            };
        }
    }
}