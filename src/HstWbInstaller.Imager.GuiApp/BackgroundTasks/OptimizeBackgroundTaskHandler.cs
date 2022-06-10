namespace HstWbInstaller.Imager.GuiApp.BackgroundTasks
{
    using System;
    using System.Threading.Tasks;
    using Core.Commands;
    using Core.Models.BackgroundTasks;
    using Extensions;
    using Hubs;
    using Microsoft.AspNetCore.SignalR;
    using Microsoft.Extensions.Logging;

    public class OptimizeBackgroundTaskHandler : IBackgroundTaskHandler
    {
        private readonly ILoggerFactory loggerFactory;
        private readonly IHubContext<ProgressHub> progressHubContext;

        public OptimizeBackgroundTaskHandler(
            ILoggerFactory loggerFactory,
            IHubContext<ProgressHub> progressHubContext)
        {
            this.loggerFactory = loggerFactory;
            this.progressHubContext = progressHubContext;
        }

        public async ValueTask Handle(IBackgroundTaskContext context)
        {
            if (context.BackgroundTask is not OptimizeBackgroundTask optimizeBackgroundTask)
            {
                return;
            }

            try
            {
                await progressHubContext.SendProgress(new Progress
                {
                    Title = optimizeBackgroundTask.Title,
                    IsComplete = false,
                    PercentComplete = 50,
                }, context.Token);

                var commandHelper = new CommandHelper();
                var optimizeCommand = new OptimizeCommand(loggerFactory.CreateLogger<OptimizeCommand>(),commandHelper, optimizeBackgroundTask.Path);

                var result = await optimizeCommand.Execute(context.Token);

                await Task.Delay(1000, context.Token);

                await progressHubContext.SendProgress(new Progress
                {
                    Title = optimizeBackgroundTask.Title,
                    IsComplete = true,
                    HasError = result.IsFaulted,
                    ErrorMessage = result.IsFaulted ? result.Error.Message : null,
                    PercentComplete = 100
                }, context.Token);
            }
            catch (Exception e)
            {
                await progressHubContext.SendProgress(new Progress
                {
                    Title = optimizeBackgroundTask.Title,
                    IsComplete = true,
                    HasError = true,
                    ErrorMessage = e.Message,
                    PercentComplete = 100
                }, context.Token);
            }
        }
    }
}