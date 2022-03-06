namespace HstWbInstaller.Imager.GuiApp.BackgroundTasks
{
    using System;
    using System.Threading.Tasks;
    using Core.Commands;
    using Core.Models.BackgroundTasks;
    using Extensions;
    using Microsoft.AspNetCore.SignalR.Client;

    public class BlankBackgroundTaskHandler : IBackgroundTaskHandler
    {
        private readonly HubConnection progressHubConnection;

        public BlankBackgroundTaskHandler(HubConnection progressHubConnection)
        {
            this.progressHubConnection = progressHubConnection;
        }

        public async ValueTask Handle(IBackgroundTaskContext context)
        {
            if (context.BackgroundTask is not BlankBackgroundTask blankBackgroundTask)
            {
                return;
            }

            try
            {
                await progressHubConnection.UpdateProgress(new Progress
                {
                    Title = blankBackgroundTask.Title,
                    IsComplete = false,
                    PercentComplete = 50,
                }, context.Token);                

                var commandHelper = new CommandHelper();
                var blankCommand = new BlankCommand(commandHelper, blankBackgroundTask.Path,
                    blankBackgroundTask.CompatibleSize ? Convert.ToInt64(blankBackgroundTask.Size * 0.95) : blankBackgroundTask.Size);

                var result = await blankCommand.Execute(context.Token);

                await Task.Delay(1000, context.Token);
                
                await progressHubConnection.UpdateProgress(new Progress
                {
                    Title = blankBackgroundTask.Title,
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
                    Title = blankBackgroundTask.Title,
                    IsComplete = true,
                    HasError = true,
                    ErrorMessage = e.Message,
                    PercentComplete = 100
                }, context.Token);
            }
        }
    }
}