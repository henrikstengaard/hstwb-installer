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
            
            Assert.Equal("/bin/bash", processStartInfo.FileName);
            Assert.Equal(workingDirectory, processStartInfo.WorkingDirectory);
            Assert.Equal(
                $"-c \"pkexec ./{command} {arguments}\"",
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
            
            Assert.Equal("/bin/bash", processStartInfo.FileName);
            Assert.Equal(workingDirectory, processStartInfo.WorkingDirectory);
            Assert.Equal(
                $"-c \"osascript -e 'do shell script \\\"./{command} {arguments}\\\" with prompt \\\"{prompt}\\\" with administrator privileges'\"",
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
            
            Assert.Equal("/bin/bash", processStartInfo.FileName);
            Assert.Equal(string.Empty, processStartInfo.WorkingDirectory);
            Assert.Equal(
                $"-c \"osascript -e 'do shell script \\\"{command} {arguments}\\\" with prompt \\\"{prompt}\\\" with administrator privileges'\"",
                processStartInfo.Arguments);
            Assert.Equal(string.Empty, processStartInfo.Verb);
        }
    }
}