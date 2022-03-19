namespace HstWbInstaller.Imager.Core.Tests
{
    using System;
    using System.IO;
    using Helpers;
    using Xunit;

    public class GivenElevateHelper
    {
        [Fact]
        public void WhenCreateWindowsRunasProcessStartInfoThenArgumentsWillElevateCommand()
        {
            var command = "hstwb-imager";
            var arguments = string.Empty;
            var workingDirectory = @"c:\program files\hstwb-installer";
            var processStartInfo =
                ElevateHelper.CreateWindowsRunasProcessStartInfo(command, arguments, workingDirectory);

            Assert.Equal(command, processStartInfo.FileName);
            Assert.Equal(workingDirectory, processStartInfo.WorkingDirectory);
            Assert.Equal(arguments, processStartInfo.Arguments);
            Assert.Equal("runas", processStartInfo.Verb);
        }

        [Fact]
        public void WhenCreateLinuxPkExecProcessStartInfoThenArgumentsWillElevateCommand()
        {
            var command = "hstwb-imager";
            var arguments = "--worker";
            var workingDirectory =
                "/home/hst";
            var processStartInfo =
                ElevateHelper.CreateLinuxPkExecProcessStartInfo(command, arguments, workingDirectory);
            
            Assert.Equal("/usr/bin/pkexec", processStartInfo.FileName);
            Assert.Equal(workingDirectory, processStartInfo.WorkingDirectory);
            Assert.Equal(
                $"bash -c \"./{command} {arguments}\"",
                processStartInfo.Arguments);
            Assert.Equal(string.Empty, processStartInfo.Verb);
        }

        [Fact]
        public void WhenCreateMacOsOsascriptProcessStartInfoThenArgumentsWillElevateCommand()
        {
            var prompt = "HstWB Imager";
            var command = "hstwb-imager";
            var arguments = "--worker";
            var workingDirectory =
                "/home/hst";
            var processStartInfo =
                ElevateHelper.CreateMacOsOsascriptProcessStartInfo(prompt, command, arguments, workingDirectory);
            
            Assert.Equal("/usr/bin/osascript", processStartInfo.FileName);
            Assert.Equal(workingDirectory, processStartInfo.WorkingDirectory);
            Assert.Equal(
                $"-e 'do shell script \"sudo \\\"./{command}\\\" {arguments}\" with prompt \"{prompt}\" with administrator privileges'",
                processStartInfo.Arguments);
            Assert.Equal(string.Empty, processStartInfo.Verb);
        }
        
        [Fact]
        public void WhenCreateMacOsOsascriptProcessStartInfoWithoutWorkingDirectoryThenArgumentsWillElevateCommand()
        {
            var prompt = "HstWB Imager";
            var command = "/home/hst/hstwb-imager";
            var arguments = "--worker";
            var workingDirectory = string.Empty;
            var processStartInfo =
                ElevateHelper.CreateMacOsOsascriptProcessStartInfo(prompt, command, arguments, workingDirectory);
            
            Assert.Equal("/usr/bin/osascript", processStartInfo.FileName);
            Assert.Equal(string.Empty, processStartInfo.WorkingDirectory);
            Assert.Equal(
                $"-e 'do shell script \"sudo \\\"{command}\\\" {arguments}\" with prompt \"{prompt}\" with administrator privileges'",
                processStartInfo.Arguments);
            Assert.Equal(string.Empty, processStartInfo.Verb);
        }
        
        [Fact]
        public void WhenCreateMacOsOsascriptSudoProcessStartInfoWithoutWorkingDirectoryThenArgumentsWillElevateCommand()
        {
            var prompt = "HstWB Imager";
            var command = "/home/hst/hstwb-imager";
            var arguments = "--worker";
            var workingDirectory = string.Empty;
            var processStartInfo =
                ElevateHelper.CreateMacOsOsascriptSudoProcessStartInfo(prompt, command, arguments, workingDirectory);

            var script = $"echo '{prompt}'; sudo bash -c '{command} {arguments} >/dev/null &'";
            var osaScriptArgs = new[]
            {
                "-e \"tell application \\\"Terminal\\\"\"",
                "-e \"activate\"",
                $"-e \"set tabId to do script \\\"{script}\\\"\"",
                "-e \"set windowId to the id of window 1 where its tab 1 = tabId\"",
                "-e \"repeat\"",
                "-e \"delay 0.1\"",
                "-e \"if not busy of tabId then exit repeat\"",
                "-e \"end repeat\"",
                "-e \"close window id windowId\"",
                "-e \"end tell\""
            };
            
            Assert.Equal("/usr/bin/osascript", processStartInfo.FileName);
            Assert.Equal(string.Empty, processStartInfo.WorkingDirectory);
            Assert.Equal(
                string.Join(" ", osaScriptArgs),
                processStartInfo.Arguments);
            Assert.Equal(string.Empty, processStartInfo.Verb);
        }
    }
}