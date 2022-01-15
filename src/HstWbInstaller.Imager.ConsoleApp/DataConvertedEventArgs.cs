namespace HstWbInstaller.Imager.ConsoleApp
{
    using System;

    public class DataConvertedEventArgs : EventArgs
    {
        public readonly long BytesConverted;

        public DataConvertedEventArgs(long bytesConverted)
        {
            BytesConverted = bytesConverted;
        }
    }
}