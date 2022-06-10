namespace HstWbInstaller.Imager.GuiApp.Models
{
    public class Settings
    {
        public enum MacOsElevateMethodEnum
        {
            OsascriptAdministrator,
            OsascriptSudo
        }

        public enum ThemeEnum
        {
            Amiga,
            Light,
            Windows,
            MacOs,
            Linux
        }
        
        public MacOsElevateMethodEnum MacOsElevateMethod { get; set; }
        //public ThemeEnum Theme { get; set; }

        public Settings()
        {
            MacOsElevateMethod = MacOsElevateMethodEnum.OsascriptSudo;
        }
    }
}