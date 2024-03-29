﻿namespace HstWbInstaller.Imager.Core.Tests
{
    using System.Linq;
    using System.Threading.Tasks;
    using Commands;
    using Xunit;

    public abstract class CommandTestBase
    {
        protected async Task<byte[]> ReadMediaBytes(ICommandHelper commandHelper, string path, long size)
        {
            var mediaResult = commandHelper.GetReadableMedia(Enumerable.Empty<IPhysicalDrive>(), path, false);
            using var media = mediaResult.Value;
            await using var stream = media.Stream;
            var bytes = new byte[size];
            var bytesRead = await stream.ReadAsync(bytes, 0, bytes.Length);

            Assert.Equal(size, bytesRead);

            return bytes;
        }
    }
}