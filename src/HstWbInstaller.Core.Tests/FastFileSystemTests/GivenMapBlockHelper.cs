namespace HstWbInstaller.Core.Tests.FastFileSystemTests
{
    using IO.FastFileSystem;
    using Xunit;

    public class GivenMapBlockHelper
    {
        [Fact]
        public void WhenBlocksAreAllocatedThenBytesDoesntHaveBitSet()
        {
            // arrange - create map for 32 blocks with all block set as free
            var blockFreeMap = new bool[32];
            for (var i = 0; i < blockFreeMap.Length; i++)
            {
                blockFreeMap[i] = true;
            }

            // arrange - set block 15 & 16 as allocated
            blockFreeMap[14] = false;
            blockFreeMap[15] = false;

            // act - convert block free map to byte array
            var bytes = MapBlockHelper.ConvertBlockFreeMapToByteArray(blockFreeMap);
            
            // bits: 11111111111111110011111111111111
            var expectedBytes = new byte[] { 0xff, 0xff, 0x3f, 0xff };
            
            Assert.Equal(expectedBytes, bytes);
        }
        
        [Fact]
        public void WhenFirstBlockIsAllocatedThenByteDoesntHaveBitSet()
        {
            // arrange - create map for 32 blocks with all block set as free
            var blockFreeMap = new bool[32];
            for (var i = 0; i < blockFreeMap.Length; i++)
            {
                blockFreeMap[i] = true;
            }

            // arrange - indicate block 0 is free
            blockFreeMap[0] = false;

            // act - convert map to byte array
            var bytes = MapBlockHelper.ConvertBlockFreeMapToByteArray(blockFreeMap);

            // assert
            Assert.Equal(4, bytes.Length);
            Assert.Equal(255, bytes[0]);
            Assert.Equal(255, bytes[1]);
            Assert.Equal(255, bytes[2]);
            Assert.Equal(255 - 1, bytes[3]); // 1st bit / 128 should not be set
        }

        private readonly byte[] bits = { 1, 2, 4, 8, 16, 32, 64, 128 };

        [Fact]
        public void WhenBlockIsAllocatedThenMappedByteDoesntHaveBitSet()
        {
            for (var bit = 0; bit < 8; bit++)
            {
                // arrange - create map for 8 blocks with block set allocated for bit 
                var blockFreeMap = new bool[8];
                for (var block = 0; block < blockFreeMap.Length; block++)
                {
                    blockFreeMap[block] = block != bit;
                }
                
                // act - convert map to byte array
                var mapBytes = MapBlockHelper.ConvertBlockFreeMapToByteArray(blockFreeMap);

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
                var mapBytes = MapBlockHelper.ConvertBlockFreeMapToByteArray(map);

                // assert - 1 map byte is returned
                Assert.Single(mapBytes);
                
                // assert - bits are not set in map bytes
                Assert.Equal(255 - bits[0] - bits[bit], mapBytes[0]);
            }
        }
    }
}