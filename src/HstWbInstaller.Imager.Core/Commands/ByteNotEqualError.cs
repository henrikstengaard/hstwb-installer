namespace HstWbInstaller.Imager.Core.Commands
{
    using HstWbInstaller.Core;

    public class ByteNotEqualError : Error
    {
        public long Offset;
        public byte SourceByte;
        public byte DestinationByte;

        public ByteNotEqualError(long offset, byte sourceByte, byte destinationByte)
        {
            Offset = offset;
            SourceByte = sourceByte;
            DestinationByte = destinationByte;
        }
    }
}