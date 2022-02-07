namespace HstWbInstaller.Core.IO.Hunks
{
    public class Code : IHunk
    {
        public uint Identifier => HunkIdentifiers.Code;
        public byte[] Data { get; set; }
    }
}