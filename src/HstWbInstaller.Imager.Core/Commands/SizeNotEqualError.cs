namespace HstWbInstaller.Imager.Core.Commands
{
    using HstWbInstaller.Core;

    public class SizeNotEqualError : Error
    {
        /// <summary>
        /// offset where size started to differ
        /// </summary>
        public long Offset;
        
        /// <summary>
        /// expected size
        /// </summary>
        public long Size;
        
        public SizeNotEqualError(long offset, long size)
        {
            Offset = offset;
            Size = size;
        }
    }
}