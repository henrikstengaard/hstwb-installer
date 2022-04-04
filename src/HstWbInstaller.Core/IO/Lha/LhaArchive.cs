namespace HstWbInstaller.Core.IO.Lha
{
    using System;
    using System.Collections.Generic;
    using System.IO;

    public class LhaArchive : IDisposable
    {
        private readonly Stream lhaStream;

        public LhaArchive(Stream lhaStream)
        {
            this.lhaStream = lhaStream;
        }

        // public IEnumerable<LhaEntry> List()
        // {
        //     
        // }

        public void Extract(Stream outputStream)
        {
            // var crcIo = new CrcIo(lha);
            // var lhExt = new LhExt(lha, crcIo);
            // lhExt.ExtractOne(input, output, header);            
        }

        public void Dispose()
        {
            lhaStream?.Dispose();
        }
    }

    public class LhaEntry
    {
    }
}