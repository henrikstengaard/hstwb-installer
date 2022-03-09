﻿namespace HstWbInstaller.Imager.GuiApp.BackgroundTasks
{
    using System.Threading.Tasks;
    using Core;
    using Core.Commands;
    using Core.Models.BackgroundTasks;
    using Extensions;
    using Microsoft.AspNetCore.SignalR.Client;

    public class InfoBackgroundTaskHandler : IBackgroundTaskHandler
    {
        private readonly HubConnection resultHubConnection;
        private readonly HubConnection errorHubConnection;
        private readonly IPhysicalDriveManager physicalDriveManager;

        public InfoBackgroundTaskHandler(HubConnection resultHubConnection, HubConnection errorHubConnection,
            IPhysicalDriveManager physicalDriveManager)
        {
            this.resultHubConnection = resultHubConnection;
            this.errorHubConnection = errorHubConnection;
            this.physicalDriveManager = physicalDriveManager;
        }

        public async ValueTask Handle(IBackgroundTaskContext context)
        {
            if (context.BackgroundTask is not InfoBackgroundTask infoBackgroundTask)
            {
                return;
            }
            
            var physicalDrives = await physicalDriveManager.GetPhysicalDrives();

            var commandHelper = new CommandHelper();
            var infoCommand = new InfoCommand(commandHelper, physicalDrives, infoBackgroundTask.Path);

            infoCommand.DiskInfoRead += async (_, args) => { await resultHubConnection.SendInfoResult(args.MediaInfo.ToViewModel()); };

            var result = await infoCommand.Execute(context.Token);
            if (result.IsFaulted)
            {
                await errorHubConnection.UpdateError(result.Error.Message, context.Token);
            }
        }
    }
}