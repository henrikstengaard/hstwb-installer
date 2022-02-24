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
    using Models;

    public class ListCommand : CommandBase
    {
        private readonly ICommandHelper commandHelper;
        private readonly IEnumerable<IPhysicalDrive> physicalDrives;

        public ListCommand(ICommandHelper commandHelper, IEnumerable<IPhysicalDrive> physicalDrives)
        {
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
                var diskSize = sourceStream.Length;

                var firstBytes = await sourceStream.ReadBytes(512 * 2048);
                var rigidDiskBlock = await commandHelper.GetRigidDiskBlock(new MemoryStream(firstBytes));

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