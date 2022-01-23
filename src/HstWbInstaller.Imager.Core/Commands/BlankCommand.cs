namespace HstWbInstaller.Imager.Core.Commands
{
    using System;
    using System.Linq;
    using System.Threading.Tasks;
    using HstWbInstaller.Core;

    public class BlankCommand : CommandBase
    {
        private readonly ICommandHelper commandHelper;
        private readonly string path;
        private readonly long? size;

        public BlankCommand(ICommandHelper commandHelper, string path, long? size)
        {
            this.commandHelper = commandHelper;
            this.path = path;
            this.size = size;
        }
        
        public override async Task<Result> Execute()
        {
            if (size is null or <= 0)
            {
                throw new ArgumentNullException(nameof(size));
            }
            
            using var media = commandHelper.GetWritableMedia(Enumerable.Empty<IPhysicalDrive>(), path, size.Value, false);
            await using var stream = media.Stream;

            if (!commandHelper.IsVhd(path))
            {
                stream.SetLength(size.Value);
            }

            return new Result();
        }
    }
}