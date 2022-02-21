namespace HstWbInstaller.Imager.Core.Commands
{
    using System;
    using System.Collections.Generic;
    using System.Threading;
    using System.Threading.Tasks;
    using HstWbInstaller.Core;

    public class InfoCommand : CommandBase
    {
        private readonly ICommandHelper commandHelper;
        private readonly IEnumerable<IPhysicalDrive> physicalDrives;
        private readonly string path;

        public InfoCommand(ICommandHelper commandHelper, IEnumerable<IPhysicalDrive> physicalDrives, string path)
        {
            this.commandHelper = commandHelper;
            this.physicalDrives = physicalDrives;
            this.path = path;
        }

        public event EventHandler<InfoReadEventArgs> DiskInfoRead;
        
        public override async Task<Result> Execute(CancellationToken token)
        {
            var sourceMedia = commandHelper.GetReadableMedia(physicalDrives, path);
            await using var sourceStream = sourceMedia.Stream;
            var diskSize = sourceStream.Length;

            var rigidDiskBlock = await commandHelper.GetRigidDiskBlock(sourceStream);
            OnDiskInfoRead(new MediaInfo
            {
                Path = path,
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