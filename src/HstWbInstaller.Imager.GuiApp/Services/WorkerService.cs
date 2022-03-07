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
        
        private Process workerProcess;
        private bool isReady;

        public WorkerService(ILogger<WorkerService> logger, AppState appState, IHubContext<ErrorHub> errorHubContext)
        {
            this.logger = logger;
            this.appState = appState;
            this.errorHubContext = errorHubContext;
            this.queue = new BlockingCollection<Core.Models.BackgroundTasks.BackgroundTask>(new ConcurrentQueue<Core.Models.BackgroundTasks.BackgroundTask>());
            this.workerProcess = null;
            this.isReady = false;

            AppDomain.CurrentDomain.ProcessExit += (_, _) =>
            {
                if (!IsRunning())
                {
                    return;
                }
                
                this.workerProcess.Kill();
            };
        }

        public bool IsRunning()
        {
            return workerProcess is { HasExited: false };
        }

        public async Task<bool> Start()
        {
            SetIsReady(false);

            var workerFileName = WorkerHelper.GetWorkerFileName(appState.ExecutingFile);
            var workerPath = Path.Combine(
                appState.AppPath,
                workerFileName);

            logger.LogDebug($"WorkerPath = '{workerPath}'");
            
            if (!File.Exists(workerPath))
            {
                logger.LogError($"Failed to start worker '{workerPath}'. Path not found!");
                return false;
            }

            var currentProcessId = Process.GetCurrentProcess().Id;
            var arguments = $"--worker --baseurl \"{appState.BaseUrl}\" --process-id {currentProcessId}";
            logger.LogDebug($"Starting worker '{workerPath}' with arguments '{arguments}'");

            var processStartInfo = ElevateHelper.GetElevatedProcessStartInfo(Constants.AppName, workerPath, arguments,
                Debugger.IsAttached || ApplicationDataHelper.HasDebugEnabled(Constants.AppName));

            logger.LogDebug($"Worker process file name '{processStartInfo.FileName}' with arguments '{processStartInfo.Arguments}'");
            
            this.workerProcess = ElevateHelper.StartElevatedProcess(processStartInfo);

            if (!workerProcess.HasExited)
            {
                return true;
            }
            
            var message =
                $"Failed to start worker '{workerPath}'. Process exited with error code {workerProcess.ExitCode}";
            await errorHubContext.SendError(message);
            logger.LogError($"Failed to start worker '{workerFileName}', error code {workerProcess.ExitCode}");

            return true;
        }

        public async Task EnqueueAsync<T>(T backgroundTask)
        {
            if (backgroundTask == null)
            {
                throw new ArgumentNullException(nameof(backgroundTask));
            }

            if (!IsRunning())
            {
                if (!await Start())
                {
                    return;
                }
            }
            
            logger.LogDebug($"Enqueue background task type '{backgroundTask.GetType().Name}'");
            this.queue.Add(new Core.Models.BackgroundTasks.BackgroundTask
            {
                Type = backgroundTask.GetType().Name,
                Payload = JsonSerializer.Serialize(backgroundTask)
            });
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
                return IsRunning() && isReady;
            }
        }

        public void SetIsReady(bool value)
        {
            if (value && !IsRunning())
            {
                return;
            }
            
            lock (LockObject)
            {
                this.isReady = value;
            }
        }
    }
}