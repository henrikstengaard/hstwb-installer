using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.SpaServices.ReactDevelopmentServer;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;

namespace HstWbInstaller.Imager.GuiApp
{
    using System;
    using System.IO;
    using System.Linq;
    using System.Threading.Tasks;
    using ElectronNET.API;
    using ElectronNET.API.Entities;

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

            services.AddControllersWithViews();

            // In production, the React files will be served from this directory
            services.AddSpaStaticFiles(configuration =>
            {
                configuration.RootPath = "ClientApp/build";
            });
        }

        // This method gets called by the runtime. Use this method to configure the HTTP request pipeline.
        public void Configure(IApplicationBuilder app, IWebHostEnvironment env)
        {
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

            Task.Run(() => ElectronBootstrap(env));
        }

        private async Task ElectronBootstrap(IWebHostEnvironment env)
        {
            if (!HybridSupport.IsElectronActive)
            {
                return;
            }
            
            var browserWindow = await Electron.WindowManager.CreateWindowAsync(
                new BrowserWindowOptions
                {
                    Width = 800,
                    Height = 600,
                    Center = true,
                    BackgroundColor = "#1A2933",
                    Frame = false,
                    WebPreferences = new WebPreferences
                    {
                        NodeIntegration = true,
                    },
                    Show = false,
                    Icon = Path.Combine(env.ContentRootPath, "hstwb-installer.ico")
                });
            browserWindow.SetMenu(Array.Empty<MenuItem>());
            
            await browserWindow.WebContents.Session.ClearCacheAsync();

            browserWindow.OnClosed += () => Electron.App.Quit();
            browserWindow.OnReadyToShow += () => browserWindow.Show();
            browserWindow.OnMaximize += () => Electron.IpcMain.Send(browserWindow, "window-maximized");
            browserWindow.OnUnmaximize += () => Electron.IpcMain.Send(browserWindow, "window-unmaximized");
            //browserWindow.WebContents.OpenDevTools();
            
            Electron.IpcMain.On("minimize-window", (args) => browserWindow.Minimize());
            Electron.IpcMain.On("maximize-window", (args) => browserWindow.Maximize());
            Electron.IpcMain.On("unmaximize-window", (args) => browserWindow.Unmaximize());
            Electron.IpcMain.On("close-window", (args) => browserWindow.Close());
        }
    }
}
