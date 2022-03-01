using Microsoft.AspNetCore.Hosting;
using Microsoft.Extensions.Hosting;

namespace HstWbInstaller.Imager.GuiApp
{
    using System;
    using System.IO;
    using System.Linq;
    using ElectronNET.API;
#if RELEASE
    using Helpers;
    using Models;
#endif
    using Serilog;
    using Serilog.Events;

    public class Program
    {
        public static void Main(string[] args)
        {
#if RELEASE
            var logFilePath = Path.Combine(ApplicationDataHelper.GetApplicationDataDir(Constants.AppName), "logs",
                "log.txt");
            if (ApplicationDataHelper.HasDebugEnabled(Constants.AppName))
            {
                Log.Logger = new LoggerConfiguration()
                    .MinimumLevel.Debug()
                    .WriteTo.File(
                        logFilePath,
                        rollingInterval: RollingInterval.Day)
                    .CreateLogger();
            }
            else
            {
                Log.Logger = new LoggerConfiguration()
                    .MinimumLevel.Error()
                    .WriteTo.File(
                        logFilePath,
                        rollingInterval: RollingInterval.Day)
                    .CreateLogger();
            }
#else
            Log.Logger = new LoggerConfiguration()
                .Enrich.FromLogContext()
                .MinimumLevel.Debug()
                .MinimumLevel.Override("Microsoft", LogEventLevel.Warning)
                .WriteTo.File(Path.Combine("logs", "log.txt"),rollingInterval: RollingInterval.Day,
                    outputTemplate: "{Timestamp:yyyy-MM-dd HH:mm:ss.fff zzz} [{Level}] ({SourceContext}) {Message}{Exception}")
                .CreateLogger();
#endif

            try
            {
                CreateHostBuilder(args).Build().Run();
            }
            catch (Exception ex)
            {
                Log.Fatal(ex, "Host terminated unexpectedly");
            }
            finally
            {
                Log.CloseAndFlush();
            }
        }

        public static IHostBuilder CreateHostBuilder(string[] args) =>
            Host.CreateDefaultBuilder(args)
                .UseSerilog()
                .ConfigureWebHostDefaults(webBuilder =>
                {
                    webBuilder.UseElectron(args);
                    webBuilder.UseStartup<Startup>();
                });
    }
}