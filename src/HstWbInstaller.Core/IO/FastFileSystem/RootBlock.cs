namespace HstWbInstaller.Core.IO.FastFileSystem
{
    using System;
    using System.Collections.Generic;

    public class RootBlock
    {
        public byte[] BlockBytes { get; set; }
        public int Checksum { get; set; }
        
        public uint Type { get; set; }
        public uint HashtableSize { get; set; }
        public int BitmapFlags { get; set; }
        public uint BitmapBlocksOffset { get; set; }
        
        /// <summary>
        /// first bitmap extension block (when there's more than 25 bitmap blocks)
        /// </summary>
        public uint BitmapExtensionBlocksOffset { get; set; }
        
        public string DiskName { get; set; }
        public DateTime RootAlterationDate { get; set; }
        public DateTime DiskAlterationDate { get; set; }
        public DateTime FileSystemCreationDate { get; set; }
        
        // FFS: first directory cache block, 0 otherwise
        public uint FirstDirectoryCacheBlock { get; set; }
        
        // block secondary type = ST_ROOT (value 1)
        public uint BlockSecondaryType { get; set; }

        public IEnumerable<BitmapBlock> BitmapBlocks { get; set; }

        public RootBlock()
        {
            Type = 2;
            HashtableSize = 0x48;
            BitmapFlags = -1;
            FirstDirectoryCacheBlock = 0;
            BlockSecondaryType = 1;

            var now = DateTime.UtcNow;
            RootAlterationDate = now;
            DiskAlterationDate = now;
            FileSystemCreationDate = now;
        }
    }
}