namespace HstWbInstaller.Imager.Core.Commands
{
    using System;
    using System.Collections.Generic;
    using System.Linq;
    using System.Threading.Tasks;
    using HstWbInstaller.Core;

    public class ConvertCommand : CommandBase
    {
        private readonly ICommandHelper commandHelper;
        private readonly IEnumerable<IPhysicalDrive> physicalDrives;
        private readonly string sourcePath;
        private readonly string destinationPath;
        private readonly long? size;

        public event EventHandler<DataProcessedEventArgs> DataProcessed;
        
        public ConvertCommand(ICommandHelper commandHelper, IEnumerable<IPhysicalDrive> physicalDrives, string sourcePath,
            string destinationPath, long? size = null)
        {
            this.commandHelper = commandHelper;
            this.physicalDrives = physicalDrives;
            this.sourcePath = sourcePath;
            this.destinationPath = destinationPath;
            this.size = size;
        }
        
        public override async Task<Result> Execute()
        {
            var physicalDrivesList = physicalDrives.ToList();
            using var sourceMedia = commandHelper.GetReadableMedia(physicalDrivesList, sourcePath, false);
            await using var sourceStream = sourceMedia.Stream;

            var rigidDiskBlock = await commandHelper.GetRigidDiskBlock(sourceStream);

            var convertSize = size ?? rigidDiskBlock?.DiskSize ?? sourceStream.Length;

            using var destinationMedia = commandHelper.GetWritableMedia(physicalDrivesList, destinationPath, convertSize, false);
            await using var destinationStream = destinationMedia.Stream;

            var isVhd = commandHelper.IsVhd(destinationPath);
            if (!isVhd)
            {
                destinationStream.SetLength(convertSize);
            }
            
            var imageConverter = new ImageConverter();
            imageConverter.DataProcessed += (_, e) =>
            {
                OnDataProcessed(e.PercentComplete, e.BytesProcessed, e.TotalBytesProcessed, e.TotalBytes);
            };
            await imageConverter.Convert(sourceStream, destinationStream, convertSize, commandHelper.IsVhd(sourcePath));

            return new Result();
        }

        private void OnDataProcessed(double percentComplete, long bytesConverted, long totalBytesConverted, long totalBytes)
        {
            DataProcessed?.Invoke(this, new DataProcessedEventArgs(percentComplete, bytesConverted, totalBytesConverted, totalBytes));
        }
    }
}