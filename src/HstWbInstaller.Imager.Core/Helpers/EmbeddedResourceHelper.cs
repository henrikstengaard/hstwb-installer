namespace HstWbInstaller.Imager.Core.Helpers
{
    using System;
    using System.IO;
    using System.Linq;
    using System.Reflection;

    public class EmbeddedResourceHelper
    {
        public static Stream GetEmbeddedResourceStream(Assembly assembly, string resourceName)
        {
            var matchedResourceName = assembly.GetManifestResourceNames()
                .FirstOrDefault(x => x.IndexOf(resourceName, StringComparison.OrdinalIgnoreCase) >= 0);

            if (string.IsNullOrEmpty(matchedResourceName))
            {
                return null;
            }

            return assembly.GetManifestResourceStream(matchedResourceName);
        }
    }
}