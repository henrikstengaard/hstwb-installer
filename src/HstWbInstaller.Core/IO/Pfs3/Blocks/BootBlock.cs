namespace HstWbInstaller.Core.IO.Pfs3.Blocks
{
    public class BootBlock
    {
        public byte[] BlockBytes { get; set; }

        public int disktype;          /* PFS\1                            */

        public BootBlock()
        {
            disktype = Constants.ID_PFS_DISK;
        }
    }
}