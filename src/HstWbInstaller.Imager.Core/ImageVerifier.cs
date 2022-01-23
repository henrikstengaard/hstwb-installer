namespace HstWbInstaller.Imager.Core
{
    using System;
    using System.IO;
    using System.Threading.Tasks;

    public class ImageVerifier
    {
        private readonly int bufferSize;
        
        public event EventHandler<DataProcessedEventArgs> DataVerified;

        public ImageVerifier(int bufferSize = 1024 * 1024)
        {
            this.bufferSize = bufferSize;
        }

        public async Task<bool> Verify(Stream source, Stream destination, long size)
        {
            var srcBuffer = new byte[bufferSize];
            var destBuffer = new byte[bufferSize];

            var totalBytesVerified = 0L;
            int srcBytesRead;
            int destBytesRead;
            do
            {
                var chunkSize = Convert.ToInt32(totalBytesVerified + bufferSize >= size ? size - totalBytesVerified : bufferSize);
                
                srcBytesRead = await source.ReadAsync(srcBuffer, 0, chunkSize);
                destBytesRead = await destination.ReadAsync(destBuffer, 0, chunkSize);

                if (srcBytesRead != destBytesRead)
                {
                    return false;
                }
                
                for (var i = 0; i < srcBytesRead; i++)
                {
                    if (srcBuffer[i] != destBuffer[i])
                    {
                        return false;
                    }
                }
                
                totalBytesVerified += chunkSize;
                var percentComplete = totalBytesVerified == 0 ? 0 : (double)100 / size * totalBytesVerified;
                OnDataVerified(percentComplete, chunkSize, totalBytesVerified, size);
            } while (srcBytesRead == bufferSize && destBytesRead == srcBytesRead);

            return true;
        }

        private void OnDataVerified(double percentComplete, long bytesVerified, long totalBytesVerified, long totalBytes)
        {
            DataVerified?.Invoke(this, new DataProcessedEventArgs(percentComplete, bytesVerified, totalBytesVerified, totalBytes));
        }
    }
}