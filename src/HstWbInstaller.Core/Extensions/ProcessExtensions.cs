namespace HstWbInstaller.Core.Extensions
{
    using System.Diagnostics;
    using System.IO;
    using System.Threading.Tasks;

    public static class ProcessExtensions
    {
        public static string RunProcess(this string command, string args = null)
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
                throw new IOException($"Failed to start process command '{command}' {(string.IsNullOrWhiteSpace(args) ? string.Empty : $" with arguments '{args}'")}");
            }
        
            return process.StandardOutput.ReadToEnd();
        }

        public static async Task<string> RunProcessAsync(this string command, string args = null)
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
                throw new IOException($"Failed to start process command '{command}' {(string.IsNullOrWhiteSpace(args) ? string.Empty : $" with arguments '{args}'")}");
            }
        
            return await process.StandardOutput.ReadToEndAsync();
        }
    }
}