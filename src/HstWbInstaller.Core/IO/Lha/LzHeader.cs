namespace HstWbInstaller.Core.IO.Lha
{
    public class LzHeader
    {
        public int HeaderSize { get; set; }
        public int SizeFieldLength { get; set; }
        public string Method { get; set; }
        public long PackedSize { get; set; }
        public long OriginalSize { get; set; }
        public int LastModifiedStamp { get; set; }
        public int Attribute { get; set; }
        public int HeaderLevel { get; set; }
        
        public string Name { get; set; }
        public short HeaderCrc { get; set; }
        public short Crc { get; set; }
        public int ExtendType { get; set; }
        public int UnixMode { get; set; }
        public short UnixGid { get; set; }
        public short UnixUid { get; set; }
        public string UnixGroupName { get; set; }
        public string UnixUserName { get; set; }
        public int UnixLastModifiedStamp { get; set; }
        public bool HasCrc { get; set; }
        
        public long HeaderOffset { get; set; }
        public byte MinorVersion { get; set; }
    }
}