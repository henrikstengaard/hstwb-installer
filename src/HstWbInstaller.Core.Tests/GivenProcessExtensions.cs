namespace HstWbInstaller.Core.Tests
{
    using System;
    using System.Threading.Tasks;
    using Extensions;
    using Xunit;
    using OperatingSystem = OperatingSystem;

    public class GivenProcessExtensions
    {
        [Fact]
        public void WhenListFilesInDirectoryThenOutputIsReturned()
        {
            string output;
            if (OperatingSystem.IsWindows())
            {
                output = "cmd.exe".RunProcess("/c dir",
                    Environment.GetEnvironmentVariable("%SYSTEMROOT%"));
            }
            else
            {
                output = "/bin/bash".RunProcess("-c \"ls -l\"");
            }

            Assert.NotNull(output);
            Assert.NotEqual(string.Empty, output);
        }

        [Fact]
        public async Task WhenListFilesInDirectoryAsyncThenOutputIsReturned()
        {
            string output;
            if (OperatingSystem.IsWindows())
            {
                output = await "cmd.exe".RunProcessAsync("/c dir",
                    Environment.GetEnvironmentVariable("%SYSTEMROOT%"));
            }
            else
            {
                output = await "/bin/bash".RunProcessAsync("-c \"ls -l\"");
            }

            Assert.NotNull(output);
            Assert.NotEqual(string.Empty, output);
        }
    }
}