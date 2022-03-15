namespace HstWbInstaller.Imager.Core.Helpers
{
    using System;
    using System.Collections.Generic;
    using System.Diagnostics;
    using System.IO;
    using System.Linq;
    using OperatingSystem = HstWbInstaller.Core.OperatingSystem;

    public static class ElevateHelper
    {
        private static IEnumerable<string> GetBashExports(string command)
        {
            var args = new List<string>(new[]
            {
                $"cd \"{Path.GetDirectoryName(command)}\";",
            });

            var environmentVariables = Environment.GetEnvironmentVariables();
            foreach (var key in environmentVariables.Keys)
            {
                args.Add($"export {key}=\"{environmentVariables[key]}\";");
            }

            return args;
            //args.Add($"\"{Path.GetFileName(command)}\"");
            //return string.Join("; ", args);
        }

        public static string[] GetBashArgs(string command, string arguments = null, bool escapeQuotes = false)
        {
            var commandArgs = new List<string>();
            if (!string.IsNullOrWhiteSpace(Path.GetDirectoryName(command)))
            {
                commandArgs.Add($"cd \"{Path.GetDirectoryName(command)}\";");
            }

            commandArgs.Add(
                $"\".{Path.DirectorySeparatorChar}{Path.GetFileName(command)}\"{(string.IsNullOrWhiteSpace(arguments) ? string.Empty : $" {arguments}")};");

            var commandLineArg = string.Join(" ", commandArgs);
            return new[]
            {
                "/bin/bash",
                "-c",
                $"\"{(escapeQuotes ? commandLineArg.Replace("\"", "\\\"") : commandLineArg)}\""
            };
        }

        public static ProcessStartInfo GetKdeSudoProcessStartInfo(string applicationName, string command,
            string arguments = null)
        {
            var kdeSudoArgs = new List<string>(new[]
            {
                "--comment",
                $"\"'{applicationName}' wants to make changes. Enter your password to allow this.\"",
                "-d",
                "--"
            });

            var args = string.Join(" ", kdeSudoArgs.Concat(GetBashArgs(command, arguments)));

            return new ProcessStartInfo("/usr/bin/kdesudo")
            {
                RedirectStandardOutput = false,
                RedirectStandardError = false,
                CreateNoWindow = true,
                UseShellExecute = true,
                Arguments = args,
            };
        }

        /// <summary>
        /// create linux pkexec process start info to run command with administrator privileges
        /// </summary>
        /// <param name="command"></param>
        /// <param name="arguments"></param>
        /// <param name="workingDirectory"></param>
        /// <param name="showWindow"></param>
        /// <returns></returns>
        public static ProcessStartInfo CreateLinuxPkExecProcessStartInfo(string command, string arguments = null,
            string workingDirectory = null, bool showWindow = true)
        {
            var script = $"{(command.StartsWith("/") ? command : $"./{command}")}{(string.IsNullOrWhiteSpace(arguments) ? string.Empty : $" {arguments}")}";

            var bashArgs = new List<string>(new[]
            {
                "bash",
                "-c",
                $"\"{script}\""
            });
            
            var args = string.Join(" ", bashArgs);
            
            return new ProcessStartInfo("/usr/bin/pkexec")
            {
                RedirectStandardOutput = false,
                RedirectStandardError = false,
                CreateNoWindow = !showWindow,
                WindowStyle = showWindow ? ProcessWindowStyle.Normal : ProcessWindowStyle.Hidden,
                UseShellExecute = true,
                Arguments = args,
                WorkingDirectory = workingDirectory ?? string.Empty
            };
        }

        /// <summary>
        /// create mac os osascript process start info to run command with administrator privileges
        /// </summary>
        /// <param name="prompt"></param>
        /// <param name="command"></param>
        /// <param name="arguments"></param>
        /// <param name="workingDirectory"></param>
        /// <param name="showWindow"></param>
        /// <returns></returns>
        public static ProcessStartInfo CreateMacOsOsascriptProcessStartInfo(string prompt, string command,
            string arguments = null, string workingDirectory = null, bool showWindow = false)
        {
            var script = $"sudo \\\"{(command.StartsWith("/") ? command : $"./{command}")}\\\"{(string.IsNullOrWhiteSpace(arguments) ? string.Empty : $" {arguments}")}";
            
            var args =
                $"-e 'do shell script \"{script}\" with prompt \"{prompt}\" with administrator privileges'";

            return new ProcessStartInfo("/usr/bin/osascript")
            {
                RedirectStandardOutput = false,
                RedirectStandardError = false,
                CreateNoWindow = !showWindow,
                WindowStyle = showWindow ? ProcessWindowStyle.Normal : ProcessWindowStyle.Hidden,
                UseShellExecute = true,
                Arguments = args,
                WorkingDirectory = workingDirectory ?? string.Empty
            };
        }

        /// <summary>
        /// create windows runas process start info to run command with administrator privileges
        /// </summary>
        /// <param name="command"></param>
        /// <param name="arguments"></param>
        /// <param name="workingDirectory"></param>
        /// <param name="showWindow"></param>
        /// <returns></returns>
        public static ProcessStartInfo CreateWindowsRunasProcessStartInfo(string command, string arguments = null,
            string workingDirectory = null, bool showWindow = false)
        {
            return new ProcessStartInfo(Path.GetFileName(command))
            {
                RedirectStandardOutput = false,
                RedirectStandardError = false,
                CreateNoWindow = !showWindow,
                WindowStyle = showWindow ? ProcessWindowStyle.Normal : ProcessWindowStyle.Hidden,
                UseShellExecute = true,
                Arguments = arguments ?? string.Empty,
                WorkingDirectory = workingDirectory ?? string.Empty,
                Verb = "runas"
            };
        }

        public static ProcessStartInfo GetElevatedProcessStartInfo(string prompt, string command,
            string arguments = null, string workingDirectory = null, bool showWindow = false)
        {
            ProcessStartInfo processStartInfo;
            if (OperatingSystem.IsWindows())
            {
                processStartInfo = CreateWindowsRunasProcessStartInfo(command, arguments, workingDirectory, showWindow);
            }
            else if (OperatingSystem.IsMacOs())
            {
                processStartInfo = CreateMacOsOsascriptProcessStartInfo(prompt, command, arguments, workingDirectory, showWindow);
            }
            else if (OperatingSystem.IsLinux())
            {
                processStartInfo = CreateLinuxPkExecProcessStartInfo(command, arguments, workingDirectory, showWindow);
            }
            else
            {
                throw new NotSupportedException("Operating system is not supported");
            }

            return processStartInfo;
        }

        public static Process StartElevatedProcess(ProcessStartInfo processStartInfo)
        {
            var process = Process.Start(processStartInfo);

            if (process == null)
            {
                throw new IOException(
                    $"Failed to start elevated process file name '{processStartInfo.FileName}' {(string.IsNullOrWhiteSpace(processStartInfo.Arguments) ? string.Empty : $" with arguments '{processStartInfo.Arguments}'")}");
            }

            return process;
        }
    }
}