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
            var processStartInfo =
                ElevateHelper.CreateWindowsRunasProcessStartInfo(@"c:\program files\hstwb-installer\hstwb-imager");
            var path =
                $"c:{Path.DirectorySeparatorChar}program files{Path.DirectorySeparatorChar}hstwb-installer";

            Assert.Equal("hstwb-imager", processStartInfo.FileName);
            Assert.Equal(path, processStartInfo.WorkingDirectory);
            Assert.Equal(string.Empty, processStartInfo.Arguments);
            Assert.Equal("runas", processStartInfo.Verb);
        }

        [Fact]
        public void WhenCreateLinuxPkExecProcessStartInfoThenArgumentsWillElevateCommand()
        {
            var processStartInfo = ElevateHelper.CreateLinuxPkExecProcessStartInfo(@"/home/hst/hstwb-imager");
            var path =
                $"{Path.DirectorySeparatorChar}home{Path.DirectorySeparatorChar}hst{Path.DirectorySeparatorChar}";

            Assert.Equal("/usr/bin/pkexec", processStartInfo.FileName);
            Assert.Equal(String.Empty, processStartInfo.WorkingDirectory);
            Assert.Equal($"--disable-internal-agent /bin/bash -c \"cd \\\"{path}\"; \\\"hstwb-imager\\\"\"",
                processStartInfo.Arguments);
            Assert.Equal(string.Empty, processStartInfo.Verb);
        }

        [Fact]
        public void WhenCreateMacOsOsascriptProcessStartInfoThenArgumentsWillElevateCommand()
        {
            var processStartInfo =
                ElevateHelper.CreateMacOsOsascriptProcessStartInfo("HstWB Imager", @"/home/hst/hstwb-imager");
            var path =
                $"{Path.DirectorySeparatorChar}home{Path.DirectorySeparatorChar}hst{Path.DirectorySeparatorChar}";
            
            Assert.Equal("osascript", processStartInfo.FileName);
            Assert.Equal(String.Empty, processStartInfo.WorkingDirectory);
            Assert.Equal(
                $"-e 'do shell script \"/bin/bash -c \"cd \\\"{path}\"; \\\"hstwb-imager\\\"\"\" with prompt \"HstWB Imager\" with administrator privileges'",
                processStartInfo.Arguments);
            Assert.Equal(string.Empty, processStartInfo.Verb);
        }
    }
}