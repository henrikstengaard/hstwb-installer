namespace HstWbInstaller.Imager.GuiApp.BackgroundTasks
{
    using System.Linq;
    using System.Threading.Tasks;
    using Core;
    using Core.Commands;
    using Core.Models.BackgroundTasks;
    using Extensions;
    using Hubs;
    using Microsoft.AspNetCore.SignalR;
    using Microsoft.Extensions.Logging;

    public class ImageFileInfoBackgroundTaskHandler : IBackgroundTaskHandler
    {
        private readonly ILoggerFactory loggerFactory;
        private readonly IHubContext<ResultHub> resultHubContext;
        private readonly IHubContext<ErrorHub> errorHubContext;

        public ImageFileInfoBackgroundTaskHandler(ILoggerFactory loggerFactory, IHubContext<ResultHub> resultHubContext,
            IHubContext<ErrorHub> errorHubContext)
        {
            this.loggerFactory = loggerFactory;
            this.resultHubContext = resultHubContext;
            this.errorHubContext = errorHubContext;
        }

        public async ValueTask Handle(IBackgroundTaskContext context)
        {
            if (context.BackgroundTask is not ImageFileInfoBackgroundTask infoBackgroundTask)
            {
                return;
            }

            var commandHelper = new CommandHelper();
            var logger = loggerFactory.CreateLogger<InfoCommand>();
            var infoCommand = new InfoCommand(logger, commandHelper, Enumerable.Empty<IPhysicalDrive>(),
                infoBackgroundTask.Path);

            infoCommand.DiskInfoRead += async (_, args) =>
            {
                await resultHubContext.SendInfoResult(args.MediaInfo.ToViewModel());
            };

            var result = await infoCommand.Execute(context.Token);
            if (result.IsFaulted)
            {
                await errorHubContext.SendError(result.Error.Message, context.Token);
            }
        }
    }
}