namespace HstWbInstaller.Core.IO.RigidDiskBlocks
{
    using System.Collections.Generic;
    using System.Linq;
    using Extensions;

    public class FileSystemHeaderBlock : BlockBase
    {
        public uint HostId { get; set; }
        public uint NextFileSysHeaderBlock { get; set; }
        public uint Flags { get; set; }
        
        public byte[] DosType { get; set; }
        public string DosTypeFormatted => DosType.FormatDosType();
        public string DosTypeHex => $"0x{DosType.FormatHex()}";

        public uint Version { get; set; }
        public string VersionFormatted => $"{Version >> 16}.{Version & 0xFFFF}";
        
        /// <summary>
        /// bits set for those of the following that need to be
        /// substituted into a standard device node for this
        /// filesystem : e.g. 0x180 to substitute SegList and GlobalVec
        /// </summary>
        public uint PatchFlags { get; set; }
        public uint Type { get; set; }
        public uint Task { get; set; }
        public uint Lock { get; set; }
        public uint Handler { get; set; }
        public uint StackSize { get; set; }
        public int Priority { get; set; }
        public int Startup { get; set; }
        public int SegListBlocks { get; set; }
        public int GlobalVec { get; set; }
        public string FileSystemName { get; set; }
        
        public IEnumerable<LoadSegBlock> LoadSegBlocks { get; set; }

        public FileSystemHeaderBlock()
        {
            HostId = 7;
            NextFileSysHeaderBlock = BlockIdentifiers.EndOfBlock;
            Flags = 0;
            PatchFlags = 384;
            GlobalVec = -1;
            FileSystemName = string.Empty;
            
            LoadSegBlocks = Enumerable.Empty<LoadSegBlock>();
        }
    }
}