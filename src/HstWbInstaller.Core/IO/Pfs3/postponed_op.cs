namespace HstWbInstaller.Core.IO.Pfs3
{
    public class postponed_op
    {
        public uint operation_id;		/* which operation is postponed */
        public uint argument1;		/* operation arguments, e.g. number of blocks */
        public uint argument2;
        public uint argument3;
    };
}