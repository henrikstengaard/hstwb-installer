using Microsoft.AspNetCore.Hosting;
using Microsoft.Extensions.Hosting;

namespace HstWbInstaller.Imager.GuiApp
{
    using System;
    using System.IO;
    using System.Threading.Tasks;
    using Bootstrappers;
    using Core.Helpers;
    using Core.Models;
    using ElectronNET.API;
    using Serilog;
    using Serilog.Events;

    public class Program
    {
        public static async Task Main(string[] args)
        {
            if (args.Length == 5 && 
                args[0].Equals("--worker", StringComparison.OrdinalIgnoreCase) && 
                args[1].Equals("--baseurl", StringComparison.OrdinalIgnoreCase) && 
                !string.IsNullOrWhiteSpace(args[2]) &&
                args[3].Equals("--process-id", StringComparison.OrdinalIgnoreCase) &&
                !string.IsNullOrWhiteSpace(args[4]))
            {
                var baseUrl = args[2];
                if (!int.TryParse(args[4], out var processId))
                {
                    processId = 0;
                }
                await WorkerBootstrapper.Start(baseUrl, processId);
                return;
            }

            var hasDebugEnabled = ApplicationDataHelper.HasDebugEnabled(Constants.AppName);
#if RELEASE
            SetupReleaseLogging(hasDebugEnabled);
#else
            SetupDebugLogging();
#endif

            try
            {
                CreateHostBuilder(args).Build().Run();
            }
            catch (Exception e)
            {
                Log.Fatal(e, "Host terminated unexpectedly");
                throw;
            }
            finally
            {
                Log.CloseAndFlush();
            }
        }

        private static IHostBuilder CreateHostBuilder(string[] args) =>
            Host.CreateDefaultBuilder(args)
                .UseSerilog()
                .ConfigureWebHostDefaults(webBuilder =>
                {
                    webBuilder.UseElectron(args);
                    webBuilder.UseStartup<Startup>();
                });

        private static void SetupReleaseLogging(bool hasDebugEnabled)
        {
            var logFilePath = Path.Combine(ApplicationDataHelper.GetApplicationDataDir(Constants.AppName), "logs",
                "log-imager.txt");
            if (hasDebugEnabled)
            {
                Log.Logger = new LoggerConfiguration()
                    .MinimumLevel.Debug()
                    .WriteTo.File(
                        logFilePath,
                        rollingInterval: RollingInterval.Day,
                        outputTemplate:
                        "{Timestamp:yyyy-MM-dd HH:mm:ss.fff zzz} [{Level}] ({SourceContext}) {Message}{NewLine}{Exception}")
                    .CreateLogger();
            }
            else
            {
                Log.Logger = new LoggerConfiguration()
                    .MinimumLevel.Error()
                    .WriteTo.File(
                        logFilePath,
                        rollingInterval: RollingInterval.Day,
                        outputTemplate:
                        "{Timestamp:yyyy-MM-dd HH:mm:ss.fff zzz} [{Level}] ({SourceContext}) {Message}{NewLine}{Exception}")
                    .CreateLogger();
            }
        }

        private static void SetupDebugLogging()
        {
            Log.Logger = new LoggerConfiguration()
                .Enrich.FromLogContext()
                .MinimumLevel.Debug()
                .MinimumLevel.Override("Microsoft", LogEventLevel.Warning)
                .WriteTo.File(Path.Combine("logs", "log-imager.txt"),rollingInterval: RollingInterval.Day,
                    outputTemplate:
                    "{Timestamp:yyyy-MM-dd HH:mm:ss.fff zzz} [{Level}] ({SourceContext}) {Message}{NewLine}{Exception}")
                .CreateLogger();
        }
    }
}