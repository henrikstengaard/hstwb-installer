namespace HstWbInstaller.Imager.Core.Commands
{
    using System.Linq;
    using System.Threading;
    using System.Threading.Tasks;
    using HstWbInstaller.Core;

    public class OptimizeCommand : CommandBase
    {
        private readonly ICommandHelper commandHelper;
        private readonly string path;

        public OptimizeCommand(ICommandHelper commandHelper, string path)
        {
            this.commandHelper = commandHelper;
            this.path = path;
        }
        
        public override async Task<Result> Execute(CancellationToken token)
        {
            if (commandHelper.IsVhd(path))
            {
                return new Result(new UnsupportedImageError(path));
            }

            var mediaResult = commandHelper.GetWritableMedia(Enumerable.Empty<IPhysicalDrive>(), path);
            if (mediaResult.IsFaulted)
            {
                return new Result(mediaResult.Error);
            }
            using var media = mediaResult.Value;
            await using var stream = media.Stream;
            var currentSize = stream.Length;

            var rigidDiskBlock = await commandHelper.GetRigidDiskBlock(stream);

            if (rigidDiskBlock == null)
            {
                // unknown image format, not optimizable
                return new Result();
            }

            if (rigidDiskBlock.DiskSize == currentSize)
            {
                // not optimizable
                return new Result();
            }
            
            if (rigidDiskBlock.DiskSize > currentSize)
            {
                // invalid image, rigid disk block larger than media size
                return new Result();
            }

            // optimize
            stream.SetLength(rigidDiskBlock.DiskSize);
            
            return new Result();
        }
    }
}