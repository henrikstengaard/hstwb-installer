namespace HstWbInstaller.Core.IO.Pfs3.Blocks
{
    public class RootBlockIndex
    {
        public class Small
        {
            /*
            struct
            {
                ULONG bitmapindex[Constants.MAXSMALLBITMAPINDEX + 1];       // 5 bitmap indexblocks with 253 bitmap blocks each
                ULONG indexblocks[Constants.MAXSMALLINDEXNR + 1];      // 99 index blocks with 253 (more if reserved blocks > 1K) anode blocks each      
            } small;
             */
            // public uint[] bitmapindex;
            // public uint[] indexblocks;
            public Union<uint> bitmapindex;
            public Union<uint> indexblocks;

            public Small(uint[] union)
            {
                // bitmapindex = new uint[Constants.MAXSMALLBITMAPINDEX + 1];
                // indexblocks = new uint[Constants.MAXSMALLINDEXNR + 1];
                bitmapindex = new Union<uint>(union, 0);
                indexblocks = new Union<uint>(union, Constants.MAXSMALLBITMAPINDEX + 1);
            }
        }

        /// <summary>
        /// union to share array between offset usage
        /// </summary>
        /// <typeparam name="T"></typeparam>
        public class Union<T>
        {
            private readonly T[] array;
            private readonly int offset;

            public Union(T[] array, int offset)
            {
                this.array = array;
                this.offset = offset;
            }

            public T this[int index]
            {
                get => array[offset + index];
                set => array[offset + index] = value;
            }
        }

        public class Large
        {
            /*
            struct 
            {
                ULONG bitmapindex[Constants.MAXBITMAPINDEX + 1];		// 104 bitmap indexblocks = max 104 G
            } large;
             */
            // public uint[] bitmapindex;
            public Union<uint> bitmapindex;

            public Large(uint[] union)
            {
                // bitmapindex = new uint[Constants.MAXSMALLINDEXNR + 1];
                bitmapindex = new Union<uint>(union, 0);
            }
        }
        
        public Small small;
        public Large large;

        /// <summary>
        /// union of uint (ULONG) for small and large structs sharing same memory area
        /// </summary>
        public uint[] union;

        public RootBlockIndex(uint[] idxUnion)
        {
            this.union = idxUnion;
            small = new Small(idxUnion);
            large = new Large(idxUnion);
        }
        
        public RootBlockIndex() : this(new uint[Constants.MAXSMALLBITMAPINDEX + 1 + Constants.MAXSMALLINDEXNR + 1])
        {
        }
    }
}