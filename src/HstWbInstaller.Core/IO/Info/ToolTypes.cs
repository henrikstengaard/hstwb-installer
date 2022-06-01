namespace HstWbInstaller.Core.IO.Info
{
    using System.Collections.Generic;

    public class ToolTypes
    {
        public uint Entries { get; set; }
        public IEnumerable<TextData> TextDatas { get; set; }

        public ToolTypes()
        {
            Entries = 4;
            TextDatas = new List<TextData>();
        }
    }
}