namespace HstWbInstaller.Core.IO.Pfs3
{
    public class anodechain
    {
        // struct anodechain
        // {
        //     struct anodechain *next;
        //     struct anodechain *prev;
        //     ULONG refcount;             /* will be discarded if refcount becomes 0 */
        //     struct anodechainnode head;
        // };
        public uint refcount;
        public anodechainnode head;

        public anodechain()
        {
            head = new anodechainnode();
        }
    }
}