namespace HstWbInstaller.Imager.Core.Helpers
{
    using System;
    using System.IO;
    using System.Reflection;
    using System.Text.Json;
    using System.Text.Json.Serialization;
    using System.Text.RegularExpressions;
    using System.Threading.Tasks;

    public static class ApplicationDataHelper
    {
        private static readonly Regex WhitespaceRegex = new("\\s+", RegexOptions.Compiled | RegexOptions.IgnoreCase);

        public static string GetApplicationDataDir(string appName)
        {
            var appDataDir = Path.Combine(Environment.GetFolderPath(OperatingSystem.IsWindows()
                    ? Environment.SpecialFolder.ApplicationData
                    : Environment.SpecialFolder.UserProfile),
                OperatingSystem.IsWindows() ? appName : $".{WhitespaceRegex.Replace(appName.ToLower(), "-")}");

            if (!Directory.Exists(appDataDir))
            {
                Directory.CreateDirectory(appDataDir);
            }

            return appDataDir;
        }

        public static bool IsLicenseAgreed(string appName)
        {
            return File.Exists(Path.Combine(GetApplicationDataDir(appName), "license_agreed.txt"));
        }

        public static async Task AgreeLicense(Assembly assembly, string appName, bool agree)
        {
            var licenseAgreedPath = Path.Combine(GetApplicationDataDir(appName), "license_agreed.txt");

            if (!agree)
            {
                if (File.Exists(licenseAgreedPath))
                {
                    File.Delete(licenseAgreedPath);
                }

                return;
            }

            var licenseText =
                await (new StreamReader(EmbeddedResourceHelper.GetEmbeddedResourceStream(assembly, "license.txt")))
                    .ReadToEndAsync();

            await File.WriteAllTextAsync(licenseAgreedPath, licenseText);
        }

        public static bool HasDebugEnabled(string appName)
        {
            return File.Exists(Path.Combine(GetApplicationDataDir(appName), "debug.txt"));
        }

        private static string GetSettingsPath(string appName)
        {
            return Path.Combine(GetApplicationDataDir(appName), "settings.json");
        }

        public static async Task<T> ReadSettings<T>(string appName)
        {
            var settingsPath = GetSettingsPath(appName);

            if (!File.Exists(settingsPath))
            {
                return default;
            }

            try
            {
                return JsonSerializer.Deserialize<T>(await File.ReadAllTextAsync(settingsPath), JsonSerializerOptions);
            }
            catch (Exception)
            {
                return default;
            }
        }

        public static async Task WriteSettings<T>(string appName, T settings)
        {
            var settingsPath = GetSettingsPath(appName);
            await File.WriteAllTextAsync(settingsPath, JsonSerializer.Serialize(settings, JsonSerializerOptions));
        }

        private static readonly JsonSerializerOptions JsonSerializerOptions = new()
        {
            WriteIndented = true,
            Converters =
            {
                new JsonStringEnumConverter()
            }
        };
    }
}