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

            // assert result
            Assert.False(result1.EndOfSectors);
            var sectors = result1.Sectors.ToList();
            Assert.Equal(3, sectors.Count);

            // assert sector 1
            var sector = sectors[0];
            Assert.Equal(0, sector.Start);
            Assert.Equal(SectorSize - 1, sector.End);
            Assert.True(sector.IsZeroFilled);
            Assert.Empty(sector.Data);

            // assert sector 2
            sector = sectors[1];
            Assert.Equal(SectorSize, sector.Start);
            Assert.Equal(2 * SectorSize - 1, sector.End);
            Assert.True(sector.IsZeroFilled);
            Assert.Empty(sector.Data);

            // assert sector 3
            sector = sectors[2];
            Assert.Equal(2 * SectorSize, sector.Start);
            Assert.Equal(3 * SectorSize - 1, sector.End);
            Assert.True(sector.IsZeroFilled);
            Assert.Empty(sector.Data);
            
            // read next sectors
            var result2 = await reader.ReadNext();

            // assert result
            Assert.False(result2.EndOfSectors);
            sectors = result2.Sectors.ToList();
            Assert.Equal(3, sectors.Count);

            // assert sector 4
            sector = sectors[0];
            Assert.Equal(3 * SectorSize, sector.Start);
            Assert.Equal(4 * SectorSize - 1, sector.End);
            Assert.True(sector.IsZeroFilled);
            Assert.Empty(sector.Data);

            // assert sector 5
            sector = sectors[1];
            Assert.Equal(4 * SectorSize, sector.Start);
            Assert.Equal(5 * SectorSize - 1, sector.End);
            Assert.False(sector.IsZeroFilled);
            Assert.Equal(sector.Data, sector5);

            // assert sector 6
            sector = sectors[2];
            Assert.Equal(5 * SectorSize, sector.Start);
            Assert.Equal(6 * SectorSize - 1, sector.End);
            Assert.False(sector.IsZeroFilled);
            Assert.Equal(sector.Data, sector6);

            // read next sectors
            var result3 = await reader.ReadNext();

            // assert result
            Assert.True(result3.EndOfSectors);
            Assert.Empty(result3.Sectors);
        }
    }
}