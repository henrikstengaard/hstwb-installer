namespace HstWbInstaller.Core.IO.FastFileSystem
{
    using System;
    using System.Collections.Generic;

    public class Entry
    {
        public enum EntryType
        {
            Root,
            Dir,
            File,
            LDir,
            LFile,
            LSoft
        }

        public EntryType Type { get; set; }
        public int Parent { get; set; }
        public string Name { get; set; }
        public string Comment { get; set; }
        public int Size { get; set; }
        public int Access { get; set; }
        public DateTime Date { get; set; }
        public int Real { get; set; }
        public int Sector { get; set; }
        public IEnumerable<Entry> SubDir { get; set; }
        public EntryBlock EntryBlock { get; set; }
    }
}