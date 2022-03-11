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

    public class InfoCommand : CommandBase
    {
        private readonly ILogger<InfoCommand> logger;
        private readonly ICommandHelper commandHelper;
        private readonly IEnumerable<IPhysicalDrive> physicalDrives;
        private readonly string path;

        public InfoCommand(ILogger<InfoCommand> logger, ICommandHelper commandHelper, IEnumerable<IPhysicalDrive> physicalDrives, string path)
        {
            this.logger = logger;
            this.commandHelper = commandHelper;
            this.physicalDrives = physicalDrives;
            this.path = path;
        }

        public event EventHandler<InfoReadEventArgs> DiskInfoRead;
        
        public override async Task<Result> Execute(CancellationToken token)
        {
            var sourceMediaResult = commandHelper.GetReadableMedia(physicalDrives, path);
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
            
            var diskSize = sourceStream.Length;
            
            logger.LogDebug($"Path '{path}', disk size '{diskSize}'");
            
            OnDiskInfoRead(new MediaInfo
            {
                Path = path,
                Model = sourceMedia.Model,
                IsPhysicalDrive = sourceMedia.IsPhysicalDrive,
                Type = sourceMedia.Type,
                DiskSize = diskSize,
                RigidDiskBlock = rigidDiskBlock
            });

            return new Result();
        }

        protected virtual void OnDiskInfoRead(MediaInfo diskInfo)
        {
            DiskInfoRead?.Invoke(this, new InfoReadEventArgs(diskInfo));
        }
    }
}