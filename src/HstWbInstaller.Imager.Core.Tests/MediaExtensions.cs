namespace HstWbInstaller.Imager.Core.Tests
{
    using System;
    using System.IO;
    using Models;

    public static class MediaExtensions
    {
        public static byte[] GetBytes(this Media media, long? size = null)
        {
            return GetBytes((MemoryStream)media.Stream, size);
        }

        private static byte[] GetBytes(MemoryStream memoryStream, long? size = null)
        {
            if (size == null)
            {
                return memoryStream.ToArray();
            }

            var bytes = new byte[size.Value];
            Array.Copy(memoryStream.ToArray(), 0, bytes, 0, size.Value);
            return bytes;
        }
    }
}