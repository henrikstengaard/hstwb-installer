namespace HstWbInstaller.Imager.GuiApp.BackgroundTasks
{
    using System;
    using System.Collections.Generic;
    using System.Linq;
    using System.Threading.Tasks;
    using Core;
    using Core.Commands;
    using Core.Helpers;
    using Core.Models.BackgroundTasks;
    using Extensions;
    using Microsoft.AspNetCore.SignalR.Client;

    public class WriteBackgroundTaskHandler : IBackgroundTaskHandler
    {
        private readonly HubConnection progressHubConnection;
        private readonly IPhysicalDriveManager physicalDriveManager;

        public WriteBackgroundTaskHandler(HubConnection progressHubConnection,
            IPhysicalDriveManager physicalDriveManager)
        {
            this.progressHubConnection = progressHubConnection;
            this.physicalDriveManager = physicalDriveManager;
        }

        public async ValueTask Handle(IBackgroundTaskContext context)
        {
            if (context.BackgroundTask is not WriteBackgroundTask writeBackgroundTask)
            {
                return;
            }

            try
            {
                var physicalDrives = await physicalDriveManager.GetPhysicalDrives();

                var commandHelper = new CommandHelper();
                var writeCommand =
                    new WriteCommand(commandHelper, physicalDrives, writeBackgroundTask.SourcePath,
                        writeBackgroundTask.DestinationPath);
                writeCommand.DataProcessed += async (_, args) =>
                {
                    await progressHubConnection.UpdateProgress(new Progress
                    {
                        Title = writeBackgroundTask.Title,
                        IsComplete = false,
                        PercentComplete = args.PercentComplete,
                        BytesProcessed = args.BytesProcessed,
                        BytesRemaining = args.BytesRemaining,
                        BytesTotal = args.BytesTotal,
                        MillisecondsElapsed = args.PercentComplete > 0
                            ? (long)args.TimeElapsed.TotalMilliseconds
                            : new long?(),
                        MillisecondsRemaining = args.PercentComplete > 0
                            ? (long)args.TimeRemaining.TotalMilliseconds
                            : new long?(),
                        MillisecondsTotal = args.PercentComplete > 0
                            ? (long)args.TimeTotal.TotalMilliseconds
                            : new long?()
                    }, context.Token);
                };

                var result = await writeCommand.Execute(context.Token);

                await progressHubConnection.UpdateProgress(new Progress
                {
                    Title = writeBackgroundTask.Title,
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
                    Title = writeBackgroundTask.Title,
                    IsComplete = true,
                    HasError = true,
                    ErrorMessage = e.Message,
                    PercentComplete = 100
                }, context.Token);
            }
        }
    }
}