namespace HstWbInstaller.Core.IO.Hunks
{
    using System.Collections.Generic;

    public class Header : IHunk
    {
        public uint Identifier => HunkIdentifiers.Header;
        public IEnumerable<string> ResidentLibraryNames { get; set; }
        public uint TableSize { get; set; }
        public uint FirstHunkSlot { get; set; }
        public uint LastHunkSlot { get; set; }
        public IEnumerable<uint> HunkSizes { get; set; }
    }
}