namespace HstWbInstaller.Imager.Core.Commands
{
    using System.Linq;
    using System.Threading;
    using System.Threading.Tasks;
    using HstWbInstaller.Core;
    using Microsoft.Extensions.Logging;

    public class OptimizeCommand : CommandBase
    {
        private readonly ILogger<OptimizeCommand> logger;
        private readonly ICommandHelper commandHelper;
        private readonly string path;

        public OptimizeCommand(ILogger<OptimizeCommand> logger, ICommandHelper commandHelper, string path)
        {
            this.logger = logger;
            this.commandHelper = commandHelper;
            this.path = path;
        }
        
        public override async Task<Result> Execute(CancellationToken token)
        {
            logger.LogDebug($"Path '{path}'");
            
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

            logger.LogDebug($"Size '{currentSize}'");

            var rigidDiskBlock = await commandHelper.GetRigidDiskBlock(stream);

            if (rigidDiskBlock == null)
            {
                logger.LogDebug($"No rigid disk block, image can't be optimized");
                // unknown image format, not optimizable
                return new Result();
            }

            if (rigidDiskBlock.DiskSize == currentSize)
            {
                logger.LogDebug($"Size equals rigid disk block disk size, image can't be optimized further");
                // not optimizable
                return new Result();
            }
            
            if (rigidDiskBlock.DiskSize > currentSize)
            {
                logger.LogDebug($"Size is smaller than rigid disk block disk size, invalid image");
                // invalid image, rigid disk block larger than media size
                return new Result();
            }

            // optimize
            var optimizedSize = rigidDiskBlock.DiskSize;
            stream.SetLength(optimizedSize);

            logger.LogDebug($"Optimized size '{optimizedSize}'");
            
            return new Result();
        }
    }
}