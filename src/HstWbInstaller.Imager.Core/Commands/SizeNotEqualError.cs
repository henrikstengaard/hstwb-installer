namespace HstWbInstaller.Imager.Core.Commands
{
    using HstWbInstaller.Core;

    public class SizeNotEqualError : Error
    {
        public long SourceSize;
        public long DestinationSize;
        
        public SizeNotEqualError(long sourceSize, long destinationSize)
        {
            SourceSize = sourceSize;
            DestinationSize = destinationSize;
        }
    }
}