using Xunit;

namespace HstWbInstaller.Core.Tests
{
    using System.Collections.Generic;
    using System.IO;
    using System.Linq;
    using System.Threading.Tasks;
    using IO.Vhds;

    public class GivenReaderWithDataSectors : SectorTestBase
    {
        [Fact]
        public async Task WhenReadNextThenDataSectorsAreReturned()
        {
            var sector1 = CreateSector();
            var sector2 = CreateSector();
            var sector3 = CreateSector();
            var sector4 = CreateSector();
            var sector5 = CreateSector(1);
            var sector6 = CreateSector(2);

            var disk = new List<byte>();
            disk.AddRange(sector1);
            disk.AddRange(sector2);
            disk.AddRange(sector3);
            disk.AddRange(sector4);
            disk.AddRange(sector5);
            disk.AddRange(sector6);
            var stream = new MemoryStream(disk.ToArray());

            // create data sector reader
            var reader = new DataSectorReader(stream, SectorSize, SectorSize * 3);

            // read next sectors
            var result1 = await reader.ReadNext();

            // assert
            Assert.False(result1.EndOfSectors);
            Assert.Empty(result1.Sectors);

            // read next sectors
            var result2 = await reader.ReadNext();

            // assert result
            Assert.False(result2.EndOfSectors);
            Assert.Single(result2.Sectors);

            // assert sector
            var sector = result2.Sectors.First();
            Assert.Equal(4 * SectorSize, sector.Start);
            Assert.Equal(6 * SectorSize - 1, sector.End);
            Assert.Equal(2 * SectorSize, sector.Data.Length);
            Assert.Equal(sector.Data, sector5.Concat(sector6));

            // read next sectors
            var result3 = await reader.ReadNext();

            // assert result
            Assert.True(result3.EndOfSectors);
            Assert.Empty(result3.Sectors);
        }
    }
}