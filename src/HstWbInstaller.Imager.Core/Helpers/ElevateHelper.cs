namespace HstWbInstaller.Imager.Core.Helpers
{
    using System;
    using System.Collections.Generic;
    using System.Diagnostics;
    using System.IO;
    using System.Linq;
    using OperatingSystem = OperatingSystem;

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

        public static string[] GetBashArgs(string command, string arguments = null)
        {
            var commandArgs = new List<string>();
            if (!string.IsNullOrWhiteSpace(Path.GetDirectoryName(command)))
            {
                commandArgs.Add($"cd \"{Path.GetDirectoryName(command)}\";");
            }

            commandArgs.Add(
                $"\"{Path.GetFileName(command)}\"{(string.IsNullOrWhiteSpace(arguments) ? string.Empty : $" {arguments}")}");

            return new[]
            {
                "/bin/bash",
                "-c",
                $"\"{string.Join(" ", commandArgs).Replace("\"", "\\\"")}\"",
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
        /// <param name="showWindow"></param>
        /// <returns></returns>
        public static ProcessStartInfo CreateLinuxPkExecProcessStartInfo(string command, string arguments = null,
            bool showWindow = true)
        {
            var pkExecArgs = new List<string>(new[]
            {
                "--disable-internal-agent"
            });

            var args = string.Join(" ", pkExecArgs.Concat(GetBashArgs(command, arguments)));

            return new ProcessStartInfo("/usr/bin/pkexec")
            {
                RedirectStandardOutput = false,
                RedirectStandardError = false,
                CreateNoWindow = !showWindow,
                WindowStyle = showWindow ? ProcessWindowStyle.Normal : ProcessWindowStyle.Hidden,
                UseShellExecute = true,
                Arguments = args,
            };
        }

        /// <summary>
        /// create mac os osascript process start info to run command with administrator privileges
        /// </summary>
        /// <param name="prompt"></param>
        /// <param name="command"></param>
        /// <param name="arguments"></param>
        /// <param name="showWindow"></param>
        /// <returns></returns>
        public static ProcessStartInfo CreateMacOsOsascriptProcessStartInfo(string prompt, string command,
            string arguments = null, bool showWindow = false)
        {
            var osaScriptArgs = new List<string>(new[]
            {
                "-e",
                $"'do shell script \"{string.Join(" ", GetBashArgs(command, arguments))}\" with prompt \"{prompt}\" with administrator privileges'"
            });

            var args = string.Join(" ", osaScriptArgs);

            return new ProcessStartInfo("osascript")
            {
                RedirectStandardOutput = false,
                RedirectStandardError = false,
                CreateNoWindow = !showWindow,
                WindowStyle = showWindow ? ProcessWindowStyle.Normal : ProcessWindowStyle.Hidden,
                UseShellExecute = true,
                Arguments = args,
            };
        }

        /// <summary>
        /// create windows runas process start info to run command with administrator privileges
        /// </summary>
        /// <param name="command"></param>
        /// <param name="arguments"></param>
        /// <param name="showWindow"></param>
        /// <returns></returns>
        public static ProcessStartInfo CreateWindowsRunasProcessStartInfo(string command, string arguments = null,
            bool showWindow = false)
        {
            return new ProcessStartInfo(Path.GetFileName(command))
            {
                CreateNoWindow = !showWindow,
                WindowStyle = showWindow ? ProcessWindowStyle.Normal : ProcessWindowStyle.Hidden,
                UseShellExecute = true,
                Arguments = arguments,
                WorkingDirectory = Path.GetDirectoryName(command) ?? string.Empty,
                Verb = "runas"
            };
        }

        public static Process StartElevatedProcess(string prompt, string command, string arguments = null,
            bool showWindow = false)
        {
            ProcessStartInfo processStartInfo;
            if (OperatingSystem.IsWindows())
            {
                processStartInfo = CreateWindowsRunasProcessStartInfo(command, arguments, showWindow);
            }
            else if (OperatingSystem.IsMacOs())
            {
                processStartInfo = CreateMacOsOsascriptProcessStartInfo(prompt, command, arguments, showWindow);
            }
            else if (OperatingSystem.IsLinux())
            {
                processStartInfo = CreateLinuxPkExecProcessStartInfo(command, arguments, showWindow);
            }
            else
            {
                throw new NotSupportedException("Operating system is not supported");
            }

            var process = Process.Start(processStartInfo);

            if (process == null)
            {
                throw new IOException(
                    $"Failed to start elevated process command '{command}' {(string.IsNullOrWhiteSpace(arguments) ? string.Empty : $" with arguments '{arguments}'")}");
            }

            return process;
        }
    }
}