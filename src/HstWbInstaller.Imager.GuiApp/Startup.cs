using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.SpaServices.ReactDevelopmentServer;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;

namespace HstWbInstaller.Imager.GuiApp
{
    using System;
    using System.Diagnostics;
    using System.IO;
    using System.Linq;
    using System.Text.Json.Serialization;
    using System.Threading.Tasks;
    using Core;
    using Core.Helpers;
    using Core.Models;
    using ElectronNET.API;
    using ElectronNET.API.Entities;
    using Helpers;
    using Hubs;
    using Microsoft.AspNetCore.Hosting.Server.Features;
    using Microsoft.Extensions.Logging;
    using Middlewares;
    using Models;
    using Services;
    using OperatingSystem = HstWbInstaller.Core.OperatingSystem;

    public class Startup
    {
        public Startup(IConfiguration configuration)
        {
            Configuration = configuration;
        }

        public IConfiguration Configuration { get; }

        // This method gets called by the runtime. Use this method to add services to the container.
        public void ConfigureServices(IServiceCollection services)
        {
            services.AddSignalR(o =>
            {
                o.EnableDetailedErrors = ApplicationDataHelper.HasDebugEnabled(Constants.AppName);
                o.MaximumReceiveMessageSize = 1024 * 1024;
            });

            services.AddControllersWithViews().AddJsonOptions(options =>
            {
                options.JsonSerializerOptions.Converters.Add(new JsonStringEnumConverter());
            });

            // In production, the React files will be served from this directory
            services.AddSpaStaticFiles(configuration =>
            {
                configuration.RootPath = "ClientApp/build";
            });

            services.AddHostedService<QueuedHostedService>();
            services.AddSingleton<IBackgroundTaskQueue>(new BackgroundTaskQueue(100));

            services.AddHostedService<BackgroundTaskService>();
            services.AddSingleton<IActiveBackgroundTaskList>(new ActiveBackgroundTaskList());
            services.AddSingleton(new AppState
            {
                AppPath = AppContext.BaseDirectory,
                ExecutingFile = WorkerHelper.GetExecutingFile(),
                IsLicenseAgreed = ApplicationDataHelper.IsLicenseAgreed(Constants.AppName),
                IsAdministrator = OperatingSystem.IsAdministrator(),
                IsElectronActive = HybridSupport.IsElectronActive,
                UseFake = Debugger.IsAttached,
                IsWindows = OperatingSystem.IsWindows(),
                IsMacOs = OperatingSystem.IsMacOs(),
                IsLinux = OperatingSystem.IsLinux()
            });
            services.AddSingleton<PhysicalDriveManagerFactory>();
            services.AddSingleton<WorkerService>();
        }

        // This method gets called by the runtime. Use this method to configure the HTTP request pipeline.
        public void Configure(IApplicationBuilder app, IWebHostEnvironment env, AppState appState, ILogger<Startup> logger)
        {
            var addresses = app.ServerFeatures.Get<IServerAddressesFeature>().Addresses.ToList();
            logger.LogDebug($"Addresses = '{string.Join(",", addresses)}'");
            appState.BaseUrl = addresses.FirstOrDefault(x => x.StartsWith("https")) ?? addresses.FirstOrDefault();
            logger.LogDebug($"Base url = '{appState.BaseUrl}'");
            
            app.UseMiddleware<ExceptionMiddleware>();
            
            if (env.IsDevelopment())
            {
                app.UseDeveloperExceptionPage();
            }
            else
            {
                app.UseExceptionHandler("/Error");
                // The default HSTS value is 30 days. You may want to change this for production scenarios, see https://aka.ms/aspnetcore-hsts.
                app.UseHsts();
            }

            app.UseHttpsRedirection();
            app.UseStaticFiles();
            app.UseSpaStaticFiles();

            app.UseRouting();

            app.UseEndpoints(endpoints =>
            {
                endpoints.MapHub<ErrorHub>("/hubs/error");
                endpoints.MapHub<ProgressHub>("/hubs/progress");
                endpoints.MapHub<ShowDialogResultHub>("/hubs/show-dialog-result");
                endpoints.MapHub<WorkerHub>("/hubs/worker");
                endpoints.MapHub<ResultHub>("/hubs/result");
                endpoints.MapControllerRoute(
                    name: "default",
                    pattern: "{controller}/{action=Index}/{id?}");
            });

            app.UseSpa(spa =>
            {
                spa.Options.SourcePath = "ClientApp";

                if (env.IsDevelopment())
                {
                    spa.UseReactDevelopmentServer(npmScript: "start");
                }
            });

            logger.LogDebug($"AppPath = '{appState.AppPath}'");            
            Task.Run(() => ElectronBootstrap(appState.AppPath));
        }

        private async Task ElectronBootstrap(string appPath)
        {
            if (!HybridSupport.IsElectronActive)
            {
                return;
            }
            
            var browserWindow = await Electron.WindowManager.CreateWindowAsync(
                new BrowserWindowOptions
                {
                    Width = 1280,
                    Height = 720,
                    Center = true,
                    BackgroundColor = "#1A2933",
                    Frame = false,
                    WebPreferences = new WebPreferences
                    {
                        NodeIntegration = true,
                    },
                    Show = false,
                    Icon = Path.Combine(appPath, "ClientApp", "build", "icon.ico")
                });
            browserWindow.RemoveMenu();
            
            await browserWindow.WebContents.Session.ClearCacheAsync();

            browserWindow.OnClosed += () => Electron.App.Quit();
            browserWindow.OnReadyToShow += () => browserWindow.Show();
            browserWindow.OnMaximize += () => Electron.IpcMain.Send(browserWindow, "window-maximized");
            browserWindow.OnUnmaximize += () => Electron.IpcMain.Send(browserWindow, "window-unmaximized");

            if (ApplicationDataHelper.HasDebugEnabled(Constants.AppName))
            {
                browserWindow.WebContents.OpenDevTools();
            }
            
            Electron.IpcMain.On("minimize-window", _ => browserWindow.Minimize());
            Electron.IpcMain.On("maximize-window", _ => browserWindow.Maximize());
            Electron.IpcMain.On("unmaximize-window", _ => browserWindow.Unmaximize());
            Electron.IpcMain.On("close-window", _ => browserWindow.Close());
        }
    }
}
