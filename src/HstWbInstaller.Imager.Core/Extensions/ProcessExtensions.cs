namespace HstWbInstaller.Imager.Core.Extensions
{
    using System.Diagnostics;
    using System.IO;
    using System.Threading.Tasks;

    public static class ProcessExtensions
    {
        public static async Task<string> RunProcess(this string command, string args = null)
        {
            var process = Process.Start(
                new ProcessStartInfo(command)
                {
                    RedirectStandardOutput = true,
                    CreateNoWindow = true,
                    UseShellExecute = false,
                    Arguments = args ?? string.Empty
                });
        
            if (process == null)
            {
                throw new IOException($"Failed to start process command '{command}'");
            }
        
            return await process.StandardOutput.ReadToEndAsync();
        }
    }
}