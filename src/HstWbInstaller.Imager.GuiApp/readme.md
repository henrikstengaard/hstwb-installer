nvm install 16.13.2
npm install -g npm@8.3.2
npm install -g npm@latest

dotnet new react -o HstWbInstaller.Imager.GuiApp --framework net5.0

Browserslist: caniuse-lite is outdated. Please run:
```
npx browserslist@latest --update-db
```

https://medium.com/bb-tutorials-and-thoughts/how-to-develop-and-build-react-app-with-net-core-backend-59d4fc5e3041

install packages:
- ElectronNET.API
- Microsoft.Extensions.PlatformAbstractions

Add to startup.cs at end of configure method
```
            var basePath = PlatformServices.Default.Application.ApplicationBasePath;

            // Open the Electron-Window here
            Task.Run(async () => await Electron.WindowManager.CreateWindowAsync(
                new BrowserWindowOptions
                {
                    Width = 800,
                    Height = 600,
                    Center = true,
                    BackgroundColor = "#1A2933",
                    Frame = false,
                    WebPreferences = new WebPreferences
                    {
                        NodeIntegration = true
                    },
                    Icon = Path.Combine(basePath, "Assets", "icon.ico")
                }));
```


cmd, cd directory with .csproj
electronize init

electronize start




## Remove unused

PS ClientApp> npm uninstall bootstrap
PS ClientApp> npm uninstall jquery


## update create react app

npm install react-scripts@latest

npm audit fix