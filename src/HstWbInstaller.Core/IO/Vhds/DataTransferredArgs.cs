namespace HstWbInstaller.Core.IO.Vhds
{
    using System;

    public class DataTransferredArgs : EventArgs
    {
        public DataTransferredArgs(int bytesTransferred)
        {
            BytesTransferred = bytesTransferred;
        }

        public int BytesTransferred { get; }
    }
}