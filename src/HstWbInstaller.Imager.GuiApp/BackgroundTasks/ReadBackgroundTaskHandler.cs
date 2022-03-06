namespace HstWbInstaller.Imager.GuiApp.BackgroundTasks
{
    using System;
    using System.Threading.Tasks;
    using Core;
    using Core.Commands;
    using Core.Models.BackgroundTasks;
    using Extensions;
    using Microsoft.AspNetCore.SignalR.Client;

    public class ReadBackgroundTaskHandler : IBackgroundTaskHandler
    {
        private readonly HubConnection progressHubConnection;
        private readonly IPhysicalDriveManager physicalDriveManager;

        public ReadBackgroundTaskHandler(HubConnection progressHubConnection, IPhysicalDriveManager physicalDriveManager)
        {
            this.progressHubConnection = progressHubConnection;
            this.physicalDriveManager = physicalDriveManager;
        }

        public async ValueTask Handle(IBackgroundTaskContext context)
        {
            if (context.BackgroundTask is not ReadBackgroundTask readBackgroundTask)
            {
                return;
            }
            
            try
            {
                var physicalDrives = await physicalDriveManager.GetPhysicalDrives();
            
                var commandHelper = new CommandHelper();
                var readCommand =
                    new ReadCommand(commandHelper, physicalDrives, readBackgroundTask.SourcePath, readBackgroundTask.DestinationPath);
                readCommand.DataProcessed += async (_, args) =>
                {
                    await progressHubConnection.UpdateProgress(new Progress
                    {
                        Title = readBackgroundTask.Title,
                        IsComplete = false,
                        PercentComplete = args.PercentComplete,
                        BytesProcessed = args.BytesProcessed,
                        BytesRemaining = args.BytesRemaining,
                        BytesTotal = args.BytesTotal,
                        MillisecondsElapsed = args.PercentComplete > 0 ? (long)args.TimeElapsed.TotalMilliseconds : new long?(),
                        MillisecondsRemaining = args.PercentComplete > 0 ? (long)args.TimeRemaining.TotalMilliseconds : new long?(),
                        MillisecondsTotal = args.PercentComplete > 0 ? (long)args.TimeTotal.TotalMilliseconds : new long?()
                    }, context.Token);                
                };
            
                var result = await readCommand.Execute(context.Token);
            
                await progressHubConnection.UpdateProgress(new Progress
                {
                    Title = readBackgroundTask.Title,
                    IsComplete = true,
                    HasError = result.IsFaulted,
                    ErrorMessage = result.IsFaulted ? result.Error.Message : null,
                    PercentComplete = 100
                }, context.Token);
            }
            catch (Exception e)
            {
                await progressHubConnection.UpdateProgress(new Progress
                {
                    Title = readBackgroundTask.Title,
                    IsComplete = true,
                    HasError = true,
                    ErrorMessage = e.Message,
                    PercentComplete = 100
                }, context.Token);
            }
        }
    }
}