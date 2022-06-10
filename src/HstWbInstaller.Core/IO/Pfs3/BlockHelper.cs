namespace HstWbInstaller.Core.IO.Pfs3
{
    using System;
    using System.Collections.Generic;
    using System.IO;
    using System.Linq;
    using Blocks;

    public class BlockHelper
    {
        

        // #define AllocBufmem(size,g) ((g->allocbufmem)(size,g))

        private static void AllocBufmemR(int size, globaldata g)
        {
            // ULONG *buffer;
            //
            // while (!(buffer = AllocBufmem (size, g)))
            //     OutOfMemory (g);
            //
            // return buffer;
            g.allocbufmem = new long[size];
        }



    }
}