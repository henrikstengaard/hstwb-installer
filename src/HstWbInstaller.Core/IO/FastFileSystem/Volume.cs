namespace HstWbInstaller.Core.IO.FastFileSystem
{
    using System;
    using System.Collections.Generic;
    using System.IO;

    public class Volume
    {
        public uint BlockSize { get; set; }
        public Stream Stream { get; set; }
        public uint FirstBlock { get; set; }
        public uint LastBlock { get; set; }
        public uint Blocks { get; set; }
        public uint PartitionStartOffset { get; set; }
        public uint Reserved { get; set; }
        public int DosType { get; set; }
        public int DataBlockSize { get; set; }
        public RootBlock RootBlock { get; set; }
        public EntryBlock CurrentDirectory { get; set; }
        public bool Mounted { get; set; }
        public bool ReadOnly { get; set; }
        
        public int BitmapSize { get; set; }
        public BitmapBlock[] BitmapTable { get; set; }
        public int[] BitmapBlocks { get; set; }
        public bool[] BitmapBlocksChg { get; set; }
        
        public bool IgnoreErrors { get; set; }
        public IList<string> Logs { get; set; }

        public Volume()
        {
            Logs = new List<string>();
            
            BitmapTable = Array.Empty<BitmapBlock>();
            BitmapBlocks = Array.Empty<int>();
            BitmapBlocksChg = Array.Empty<bool>();
        }
    }
}