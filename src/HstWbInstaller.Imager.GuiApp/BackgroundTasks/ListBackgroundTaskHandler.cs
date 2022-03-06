namespace HstWbInstaller.Imager.GuiApp.BackgroundTasks
{
    using System.Linq;
    using System.Threading.Tasks;
    using Core;
    using Core.Commands;
    using Core.Models.BackgroundTasks;
    using Extensions;
    using Microsoft.AspNetCore.SignalR.Client;
    using Models;

    public class ListBackgroundTaskHandler : IBackgroundTaskHandler
    {
        private readonly HubConnection resultHubConnection;
        private readonly HubConnection errorHubConnection;
        private readonly IPhysicalDriveManager physicalDriveManager;

        public ListBackgroundTaskHandler(
            HubConnection resultHubConnection,
            HubConnection errorHubConnection,
            IPhysicalDriveManager physicalDriveManager)
        {
            this.resultHubConnection = resultHubConnection;
            this.errorHubConnection = errorHubConnection;
            this.physicalDriveManager = physicalDriveManager;
        }

        public async ValueTask Handle(IBackgroundTaskContext context)
        {
            var physicalDrives = await physicalDriveManager.GetPhysicalDrives();

            var commandHelper = new CommandHelper();
            var listCommand = new ListCommand(commandHelper, physicalDrives);

            listCommand.ListRead += async (_, args) =>
            {
                await resultHubConnection.SendListResult(args.MediaInfos.Select(x => x.ToViewModel()).ToList());
            };

            var result = await listCommand.Execute(context.Token);
            if (result.IsFaulted)
            {
                await errorHubConnection.UpdateError(result.Error.Message, context.Token);
            }
        }
    }
}