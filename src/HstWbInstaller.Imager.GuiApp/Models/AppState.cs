namespace HstWbInstaller.Imager.GuiApp.Models
{
    public class AppState
    {
        public bool IsLicenseAgreed { get; set; }
        public bool IsAdministrator { get; set; }
        public bool IsElectronActive { get; set; }
        public bool UseFake { get; set; }
        public string BaseUrl { get; set; }
        public string AppPath { get; set; }
        
    }
}