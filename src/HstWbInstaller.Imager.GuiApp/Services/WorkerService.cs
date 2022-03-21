namespace HstWbInstaller.Imager.GuiApp.Services
{
    using System;
    using System.Collections.Concurrent;
    using System.Collections.Generic;
    using System.Diagnostics;
    using System.IO;
    using System.Linq;
    using System.Text.Json;
    using System.Threading.Tasks;
    using Core.Helpers;
    using Core.Models;
    using Extensions;
    using Helpers;
    using Hubs;
    using Microsoft.AspNetCore.SignalR;
    using Microsoft.Extensions.Logging;
    using Models;

    public class WorkerService
    {
        private readonly ILogger<WorkerService> logger;
        private readonly AppState appState;
        private readonly IHubContext<ErrorHub> errorHubContext;
        private readonly BlockingCollection<Core.Models.BackgroundTasks.BackgroundTask> queue;
        private static readonly object LockObject = new();
        
        private int workerProcessId;

        public WorkerService(ILogger<WorkerService> logger, AppState appState, IHubContext<ErrorHub> errorHubContext)
        {
            this.logger = logger;
            this.appState = appState;
            this.errorHubContext = errorHubContext;
            this.queue = new BlockingCollection<Core.Models.BackgroundTasks.BackgroundTask>(new ConcurrentQueue<Core.Models.BackgroundTasks.BackgroundTask>());
            this.workerProcessId = 0;
        }

        public bool IsRunning()
        {
            lock (LockObject)
            {
                if (workerProcessId == 0)
                {
                    return false;
                }

                try
                {
                    var process = Process.GetProcessById(workerProcessId);
                    if (process.HasExited)
                    {
                        logger.LogDebug($"Worker process id {workerProcessId} has exited");
                        SetWorkerProcessId(0);
                        return false;
                    }
                }
                catch (Exception e)
                {
                    logger.LogError(e, $"Failed to get worker process id {workerProcessId}");
                    SetWorkerProcessId(0);
                    return false;
                }

                logger.LogDebug($"Worker process id {workerProcessId} is running");
                return true;
            }
        }

        public async Task<bool> Start()
        {
            var settings = await ApplicationDataHelper.ReadSettings<Settings>(Constants.AppName) ?? new Settings();
            
            var workerCommand = WorkerHelper.GetWorkerFileName(appState.ExecutingFile);
            var workerPath = Path.Combine(
                appState.AppPath,
                workerCommand);

            logger.LogDebug($"Worker path = '{workerPath}'");
            
            if (!File.Exists(workerPath))
            {
                logger.LogError($"Failed to start worker '{workerPath}'. Path not found!");
                return false;
            }

            var currentProcessId = Process.GetCurrentProcess().Id;
            var arguments = $"--worker --baseurl {appState.BaseUrl} --process-id {currentProcessId}";
            logger.LogDebug($"Starting worker '{workerPath}' with arguments '{arguments}'");

            var processStartInfo = ElevateHelper.GetElevatedProcessStartInfo(
                $"{Constants.AppName} needs administrator privileges for raw disk access", workerCommand, arguments,
                appState.AppPath, Debugger.IsAttached || ApplicationDataHelper.HasDebugEnabled(Constants.AppName), 
                settings.MacOsElevateMethod == Settings.MacOsElevateMethodEnum.OsascriptSudo);

            logger.LogDebug($"Worker process file name '{processStartInfo.FileName}' with arguments '{processStartInfo.Arguments}'");
            
            var workerProcess = ElevateHelper.StartElevatedProcess(processStartInfo);

            if (!workerProcess.HasExited || workerProcess.ExitCode == 0)
            {
                return true;
            }
            
            var message =
                $"Failed to start worker '{workerPath}'. Process exited with error code {workerProcess.ExitCode}";
            await errorHubContext.SendError(message);
            logger.LogError($"Failed to start worker '{workerCommand}', error code {workerProcess.ExitCode}");
            
            return true;
        }

        public async Task EnqueueAsync<T>(T backgroundTask)
        {
            if (backgroundTask == null)
            {
                throw new ArgumentNullException(nameof(backgroundTask));
            }

            logger.LogDebug($"Enqueue background task type '{backgroundTask.GetType().Name}'");
            this.queue.Add(new Core.Models.BackgroundTasks.BackgroundTask
            {
                Type = backgroundTask.GetType().Name,
                Payload = JsonSerializer.Serialize(backgroundTask)
            });
            
            if (!IsRunning())
            {
                await Start();
            }
        }

        public Task<IEnumerable<Core.Models.BackgroundTasks.BackgroundTask>> DequeueAsync()
        {
            logger.LogDebug("Dequeue background tasks");
            
            var backgroundTasks = new List<Core.Models.BackgroundTasks.BackgroundTask>();
            do
            {
                var backgroundTask = this.queue.Take();
                backgroundTasks.Add(backgroundTask);
            } while (this.queue.Count > 0);

            logger.LogDebug($"Dequeued background tasks '{(string.Join(",", backgroundTasks.Select(x => JsonSerializer.Serialize(x))))}'");
            
            return Task.FromResult(backgroundTasks.AsEnumerable());
        }

        public bool IsReady()
        {
            lock (LockObject)
            {
                return workerProcessId != 0;
            }
        }

        public void SetWorkerProcessId(int processId)
        {
            logger.LogDebug($"Set worker process id = {processId}");

            lock (LockObject)
            {
                this.workerProcessId = processId;
            }
        }
    }
}