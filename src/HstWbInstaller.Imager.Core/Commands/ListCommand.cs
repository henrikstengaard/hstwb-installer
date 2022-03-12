namespace HstWbInstaller.Imager.Core.Commands
{
    using System;
    using System.Collections.Generic;
    using System.IO;
    using System.Threading;
    using System.Threading.Tasks;
    using HstWbInstaller.Core;
    using HstWbInstaller.Core.Extensions;
    using HstWbInstaller.Core.IO.RigidDiskBlocks;
    using Microsoft.Extensions.Logging;
    using Models;

    public class ListCommand : CommandBase
    {
        private readonly ILogger<ListCommand> logger;
        private readonly ICommandHelper commandHelper;
        private readonly IEnumerable<IPhysicalDrive> physicalDrives;

        public ListCommand(ILogger<ListCommand> logger, ICommandHelper commandHelper, IEnumerable<IPhysicalDrive> physicalDrives)
        {
            this.logger = logger;
            this.commandHelper = commandHelper;
            this.physicalDrives = physicalDrives;
        }

        public event EventHandler<ListReadEventArgs> ListRead;

        public override async Task<Result> Execute(CancellationToken token)
        {
            var mediaInfos = new List<MediaInfo>();
            foreach (var physicalDrive in physicalDrives)
            {
                await using var sourceStream = physicalDrive.Open();

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

                logger.LogDebug($"Physical drive size '{physicalDrive.Size}'");
                
                var streamSize = sourceStream.Length;
                logger.LogDebug($"Stream size '{streamSize}'");

                var diskSize = streamSize is > 0 ? streamSize : physicalDrive.Size;
                
                logger.LogDebug($"Path '{physicalDrive.Path}', disk size '{diskSize}'");
                
                mediaInfos.Add(new MediaInfo
                {
                    Path = physicalDrive.Path,
                    Model = physicalDrive.Model,
                    IsPhysicalDrive = true,
                    Type = Media.MediaType.Raw,
                    DiskSize = diskSize,
                    RigidDiskBlock = rigidDiskBlock
                });
            }

            OnListRead(mediaInfos);

            return new Result();
        }
        
        protected virtual void OnListRead(IEnumerable<MediaInfo> mediaInfos)
        {
            ListRead?.Invoke(this, new ListReadEventArgs(mediaInfos));
        }
    }
}