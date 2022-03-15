namespace HstWbInstaller.Imager.Core.Commands
{
    using System;
    using System.Collections.Generic;
    using System.IO;
    using System.Linq;
    using System.Threading;
    using System.Threading.Tasks;
    using HstWbInstaller.Core;
    using HstWbInstaller.Core.Extensions;
    using HstWbInstaller.Core.IO.RigidDiskBlocks;
    using Microsoft.Extensions.Logging;

    public class WriteCommand : CommandBase
    {
        private readonly ILogger<WriteCommand> logger;
        private readonly ICommandHelper commandHelper;
        private readonly IEnumerable<IPhysicalDrive> physicalDrives;
        private readonly string sourcePath;
        private readonly string destinationPath;
        private readonly long? size;

        public event EventHandler<DataProcessedEventArgs> DataProcessed;
        
        public WriteCommand(ILogger<WriteCommand> logger, ICommandHelper commandHelper, IEnumerable<IPhysicalDrive> physicalDrives, string sourcePath,
            string destinationPath, long? size = null)
        {
            this.logger = logger;
            this.commandHelper = commandHelper;
            this.physicalDrives = physicalDrives;
            this.sourcePath = sourcePath;
            this.destinationPath = destinationPath;
            this.size = size;
        }

        public override async Task<Result> Execute(CancellationToken token)
        {
            var physicalDrivesList = physicalDrives.ToList();
            var sourceMediaResult = commandHelper.GetReadableMedia(physicalDrivesList, sourcePath, false);
            if (sourceMediaResult.IsFaulted)
            {
                return new Result(sourceMediaResult.Error);
            }
            using var sourceMedia = sourceMediaResult.Value;
            await using var sourceStream = sourceMedia.Stream;

            RigidDiskBlock rigidDiskBlock = null;
            try
            {
                var firstBytes = await sourceStream.ReadBytes(512 * 2048);
                rigidDiskBlock = await commandHelper.GetRigidDiskBlock(new MemoryStream(firstBytes));
            }
            catch (Exception)
            {
                // ignored
            }

            var sourceSize = sourceMedia.Size;
            var writeSize = size is > 0 ? size.Value : rigidDiskBlock?.DiskSize ?? sourceSize;

            logger.LogDebug($"Size '{(size is > 0 ? size.Value : "N/A")}'");
            logger.LogDebug($"Source size '{sourceSize}'");
            logger.LogDebug($"Rigid disk block size '{(rigidDiskBlock == null ? "N/A" : rigidDiskBlock.DiskSize)}'");
            logger.LogDebug($"Write size '{writeSize}'");
            
            var destinationMediaResult = commandHelper.GetWritableMedia(physicalDrivesList, destinationPath, writeSize);
            if (destinationMediaResult.IsFaulted)
            {
                return new Result(destinationMediaResult.Error);
            }
            using var destinationMedia = destinationMediaResult.Value;
            await using var destinationStream = destinationMedia.Stream;

            var imageConverter = new ImageConverter();
            imageConverter.DataProcessed += (_, e) =>
            {
                OnDataProcessed(e.PercentComplete, e.BytesProcessed, e.BytesRemaining, e.BytesTotal, e.TimeElapsed,
                    e.TimeRemaining, e.TimeTotal);
            };
            await imageConverter.Convert(token, sourceStream, destinationStream, writeSize);
            
            return new Result();
        }

        private void OnDataProcessed(double percentComplete, long bytesProcessed, long bytesRemaining, long bytesTotal,
            TimeSpan timeElapsed, TimeSpan timeRemaining, TimeSpan timeTotal)
        {
            DataProcessed?.Invoke(this,
                new DataProcessedEventArgs(percentComplete, bytesProcessed, bytesRemaining, bytesTotal, timeElapsed,
                    timeRemaining, timeTotal));
        }
    }
}