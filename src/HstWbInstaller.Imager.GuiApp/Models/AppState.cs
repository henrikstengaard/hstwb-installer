namespace HstWbInstaller.Imager.GuiApp.Models
{
    public class AppState
    {
        public bool IsLicenseAgreed { get; set; }
        public bool IsAdministrator { get; set; }
        public bool IsElectronActive { get; set; }
        public bool IsWindows { get; set; }
        public bool IsMacOs { get; set; }
        public bool IsLinux { get; set; }
        public bool UseFake { get; set; }
        public string BaseUrl { get; set; }
        public string AppPath { get; set; }
        public string ExecutingFile { get; set; }
        public Settings Settings { get; set; }

        public AppState()
        {
            Settings = new Settings();
        }
    }
}