namespace HstWbInstaller.Core.Extensions
{
    using System;
    using System.Diagnostics;
    using System.IO;
    using System.Threading;
    using System.Threading.Tasks;

    public static class ProcessExtensions
    {
        public static string RunProcess(this string command, string args = null, string workingDirectory = null, int successExitCode = 0)
        {
            var process = StartProcess(command, args, workingDirectory);

            var standardOutput = process.StandardOutput.ReadToEnd(); 
            var standardError = process.StandardError.ReadToEnd();

            if (process.HasExited && process.ExitCode != successExitCode)
            {
                throw new IOException(string.Concat(standardOutput, Environment.NewLine, standardError));
            }
            
            return standardOutput;
        }

        public static async Task<string> RunProcessAsync(this string command, string args = null, string workingDirectory = null, int successExitCode = 0, CancellationToken token = default)
        {
            var process = StartProcess(command, args, workingDirectory);

            var standardOutput = await process.StandardOutput.ReadToEndAsync(); 
            var standardError = await process.StandardError.ReadToEndAsync();
            
            if (process.HasExited && process.ExitCode != successExitCode)
            {
                throw new IOException(string.Concat(standardOutput, Environment.NewLine, standardError));
            }
            
            return standardOutput;
        }
        
        private static Process StartProcess(string command, string args = null, string workingDirectory = null)
        {
            var process = Process.Start(
                new ProcessStartInfo(command)
                {
                    RedirectStandardOutput = true,
                    RedirectStandardError = true,
                    CreateNoWindow = true,
                    UseShellExecute = false,
                    Arguments = args ?? string.Empty,
                    WorkingDirectory = workingDirectory ?? string.Empty,
                });
        
            if (process == null)
            {
                throw new IOException($"Failed to start process command '{command}' {(string.IsNullOrWhiteSpace(args) ? string.Empty : $" with arguments '{args}'")}");
            }

            process.EnableRaisingEvents = true;
            
            return process;
        }
    }
}