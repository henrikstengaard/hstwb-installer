namespace HstWbInstaller.Core.IO.Pfs3
{
    public class RootBlock
    {
        public string DiskName { get; set; }
        public long BlocksFree { get; set; }
        public long AlwaysFree { get; set; }
        public long DiskSize { get; set; }
    }
}