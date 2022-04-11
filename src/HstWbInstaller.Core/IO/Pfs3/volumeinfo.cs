namespace HstWbInstaller.Core.IO.Pfs3
{
    public class volumeinfo
    {
        public uint root;                   // 0 =>it's a volumeinfo; <>0 => it's a fileinfo
        public volumedata volume;
    }
}