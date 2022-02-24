namespace HstWbInstaller.Imager.Core.Tests
{
    using System;
    using System.IO;
    using System.Runtime.InteropServices;
    using System.Text;
    using System.Threading;
    using System.Threading.Tasks;
    using Apis;
    using Commands;
    using PhysicalDrives;
    using Xunit;

    public class GivenBlankCommand : CommandTestBase
    {
        [Fact]
        public async Task WhenCreateBlankImgThenDataIzZeroFilled()
        {
            // arrange
            var path = $"{Guid.NewGuid()}.img";
            var size = 512 * 512;
            var fakeCommandHelper = new FakeCommandHelper(writeableMediaPaths: new[] { path });
            var cancellationTokenSource = new CancellationTokenSource();

            // act - create blank
            var blankCommand = new BlankCommand(fakeCommandHelper, path, size);
            var result = await blankCommand.Execute(cancellationTokenSource.Token);
            Assert.True(result.IsSuccess);

            // assert data is zero filled
            var sourceBytes = new byte[size];
            var destinationBytes = fakeCommandHelper.GetMedia(path).GetBytes();
            Assert.Equal(sourceBytes, destinationBytes);
        }

        [Fact]
        public async Task WhenCreateBlankVhdThenDataIzZeroFilled()
        {
            // arrange
            var path = $"{Guid.NewGuid()}.vhd";
            var size = 512 * 512;
            var fakeCommandHelper = new FakeCommandHelper();
            var cancellationTokenSource = new CancellationTokenSource();

            // act - create blank
            var blankCommand = new BlankCommand(fakeCommandHelper, path, size);
            var result = await blankCommand.Execute(cancellationTokenSource.Token);
            Assert.True(result.IsSuccess);

            // get destination bytes from vhd
            var destinationBytes = await ReadMediaBytes(fakeCommandHelper, path, size);
            var destinationPathSize = new FileInfo(path).Length;

            // assert vhd is less than size
            Assert.True(destinationPathSize < size);

            // assert data is zero filled
            var sourceBytes = new byte[size];
            Assert.Equal(sourceBytes, destinationBytes);

            // delete vhd file
            File.Delete(path);
        }
    }

    public class GivenDeviceApi
    {
        [Fact]
        public async Task When()
        {
            char[] buffer = new char[260];
            var returnSize = Kernel32.QueryDosDeviceW(@"Volume{99b7dbed-93ea-11ec-9eea-3c6aa7c541ca}", buffer, (uint)buffer.Length);
            var lastError = Marshal.GetLastWin32Error();            
            
            //string realPath = path;
            StringBuilder pathInformation = new StringBuilder(250);
            //string deviceName = @"\\?\Volume{99b7dbed-93ea-11ec-9eea-3c6aa7c541ca}\";
            string deviceName = "Volume{99b7dbed-93ea-11ec-9eea-3c6aa7c541ca}";
            Kernel32.QueryDosDevice(deviceName, pathInformation, 250);
            var t = pathInformation.ToString();
            
            
            var stream = new WindowsPhysicalDriveStream("\\\\.\\PHYSICALDRIVE2", 0, true);
            stream.Seek(0, SeekOrigin.Begin);
            // var safeFileHandle = DeviceApi.CreateFile("\\\\.\\PHYSICALDRIVE2",
            //     DeviceApi.GENERIC_WRITE,
            //     DeviceApi.FILE_SHARE_NONE,
            //     IntPtr.Zero,
            //     DeviceApi.OPEN_EXISTING,
            //     0,
            //     IntPtr.Zero);
            //
            var buffer2 = new byte[512 * 2048];
            stream.Write(buffer2, 0, buffer.Length);
            // var result = DeviceApi.WriteFile(safeFileHandle, buffer, Convert.ToUInt32(buffer.Length), out var bytesWritten, IntPtr.Zero);
            //
            // safeFileHandle.Close();
            // safeFileHandle.Dispose();
        }
    }
}