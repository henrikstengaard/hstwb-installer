namespace HstWbInstaller.Core
{
    using System;
    using System.Runtime.InteropServices;
    using System.Security.Principal;
    using Extensions;

    public static class OperatingSystem
    {
        public static bool IsWindows() =>
            RuntimeInformation.IsOSPlatform(OSPlatform.Windows);

        public static bool IsMacOs() =>
            RuntimeInformation.IsOSPlatform(OSPlatform.OSX);

        public static bool IsLinux() =>
            RuntimeInformation.IsOSPlatform(OSPlatform.Linux);
        
        // https://github.com/dotnet/standard/issues/779
        // https://github.com/dotnet/runtime/issues/25118
        public static bool IsAdministrator()
        {
            if (IsWindows())
            {
#pragma warning disable CA1416
                using var identity = WindowsIdentity.GetCurrent();
                var principal = new WindowsPrincipal(identity);
                return principal.IsInRole(WindowsBuiltInRole.Administrator);
#pragma warning restore CA1416
            }

            // linux root has user id 0
            /* environment variable: EUID
#!/bin/bash
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi
             */
            // 
            var uidOutput = "id".RunProcess("-u");
            return uidOutput.Trim().Equals("0", StringComparison.OrdinalIgnoreCase);
        }
    }
}