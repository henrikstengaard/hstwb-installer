namespace HstWbInstaller.Core.Tests.FastFileSystemTests
{
    using IO.FastFileSystem;
    using Xunit;

    public class GivenMapBlockHelper
    {
        [Fact]
        public void WhenFirstBlockIsAllocatedThenMappedByteDoesntHaveBitSet()
        {
            // arrange - create map for 32 blocks with all block set as free
            var map = new bool[32];
            for (var i = 0; i < map.Length; i++)
            {
                map[i] = true;
            }

            // arrange - indicate block 0 is free
            map[0] = false;

            // act - convert map to byte array
            var mapBytes = MapBlockHelper.ConvertMapToByteArray(map);

            // assert
            Assert.Equal(4, mapBytes.Length);
            Assert.Equal(255 - 128, mapBytes[0]); // 1st bit / 128 should not be set
            Assert.Equal(255, mapBytes[1]);
            Assert.Equal(255, mapBytes[2]);
            Assert.Equal(255, mapBytes[3]);
        }

        private readonly byte[] bits = new byte[]{ 128, 64, 32, 16, 8, 4, 2, 1 };

        [Fact]
        public void WhenBlockIsAllocatedThenMappedByteDoesntHaveBitSet()
        {
            for (var bit = 0; bit < 8; bit++)
            {
                // arrange - create map for 8 blocks with block set allocated for bit 
                var map = new bool[8];
                for (var block = 0; block < map.Length; block++)
                {
                    map[block] = block != bit;
                }
                
                // act - convert map to byte array
                var mapBytes = MapBlockHelper.ConvertMapToByteArray(map);

                // assert - 1 map byte is returned
                Assert.Single(mapBytes);
                
                // assert - bit is not set in map bytes
                Assert.Equal(255 - bits[bit], mapBytes[0]);
            }
        }
        
        [Fact]
        public void WhenBlocksAreAllocatedThenMappedByteDoesntHaveBitsSet()
        {
            for (var bit = 1; bit < 8; bit++)
            {
                // arrange - create map for 8 blocks with block set allocated for bit 
                var map = new bool[8];
                for (var block = 0; block < map.Length; block++)
                {
                    map[block] = block != bit;
                }
                
                // arrange - always set block 1 to allocated
                map[0] = false;
                
                // act - convert map to byte array
                var mapBytes = MapBlockHelper.ConvertMapToByteArray(map);

                // assert - 1 map byte is returned
                Assert.Single(mapBytes);
                
                // assert - bits are not set in map bytes
                Assert.Equal(255 - bits[0] - bits[bit], mapBytes[0]);
            }
        }
    }
}