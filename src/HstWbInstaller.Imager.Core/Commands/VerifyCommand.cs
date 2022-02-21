namespace HstWbInstaller.Imager.Core.Commands
{
    using System;
    using System.Collections.Generic;
    using System.Linq;
    using System.Threading;
    using System.Threading.Tasks;
    using HstWbInstaller.Core;

    public class VerifyCommand : CommandBase
    {
        private readonly ICommandHelper commandHelper;
        private readonly IEnumerable<IPhysicalDrive> physicalDrives;
        private readonly string sourcePath;
        private readonly string destinationPath;
        private readonly long? size;

        public event EventHandler<DataProcessedEventArgs> DataProcessed;
        
        public VerifyCommand(ICommandHelper commandHelper, IEnumerable<IPhysicalDrive> physicalDrives, string sourcePath,
            string destinationPath, long? size = null)
        {
            this.commandHelper = commandHelper;
            this.physicalDrives = physicalDrives;
            this.sourcePath = sourcePath;
            this.destinationPath = destinationPath;
            this.size = size;
        }
        
        public override async Task<Result> Execute(CancellationToken token)
        {
            var physicalDrivesList = physicalDrives.ToList();
            using var sourceMedia = commandHelper.GetReadableMedia(physicalDrivesList, sourcePath);
            await using var sourceStream = sourceMedia.Stream;

            var rigidDiskBlock = await commandHelper.GetRigidDiskBlock(sourceStream);

            using var destinationMedia = commandHelper.GetReadableMedia(physicalDrivesList, destinationPath);
            await using var destinationStream = destinationMedia.Stream;

            var verifySize = size ?? rigidDiskBlock?.DiskSize ?? sourceStream.Length;

            // var bufferSize = 512 * 512;
            // var srcBuffer = new byte[bufferSize];
            // var destBuffer = new byte[bufferSize];
            // int srcBytesRead;
            // long offset = 0;
            // do
            // {
            //     var verifyBytes = Convert.ToInt32(offset + bufferSize > verifySize ? verifySize - offset : bufferSize);
            //     srcBytesRead = await sourceStream.ReadAsync(srcBuffer, 0, verifyBytes);
            //     var destBytesRead = await destinationStream.ReadAsync(destBuffer, 0, verifyBytes);
            //     
            //     if (srcBytesRead != destBytesRead)
            //     {
            //         return new Result(new SizeNotEqualError(offset + srcBytesRead, offset + destBytesRead));
            //     }
            //     
            //     for (int i = 0; i < verifyBytes; i++)
            //     {
            //         if (srcBuffer[i] == destBuffer[i])
            //         {
            //             continue;
            //         }
            //         
            //         return new Result(new ByteNotEqualError(offset + i, srcBuffer[i], destBuffer[i]));
            //     }
            //
            //     offset += verifyBytes;
            //     var percentComplete = offset == 0 ? 0 : (double)100 / verifySize * offset;
            //     OnDataProcessed(percentComplete, verifyBytes, offset, verifySize);
            // } while (srcBytesRead == bufferSize && offset < verifySize);

            var imageVerifier = new ImageVerifier();
            imageVerifier.DataProcessed += (_, e) =>
            {
                OnDataProcessed(e.PercentComplete, e.BytesProcessed, e.BytesRemaining, e.BytesTotal, e.TimeElapsed,
                    e.TimeRemaining, e.TimeTotal);
            };
            return await imageVerifier.Verify(token, sourceStream, destinationStream, verifySize);
        }

        private void OnDataProcessed(double percentComplete, long bytesProcessed, long bytesRemaining, long bytesTotal,
            TimeSpan timeElapsed, TimeSpan timeTotal, TimeSpan timeRemaining)
        {
            DataProcessed?.Invoke(this,
                new DataProcessedEventArgs(percentComplete, bytesProcessed, bytesRemaining, bytesTotal, timeElapsed,
                    timeRemaining, timeTotal));
        }
    }
}