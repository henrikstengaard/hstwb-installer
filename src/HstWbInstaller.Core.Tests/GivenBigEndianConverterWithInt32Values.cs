namespace HstWbInstaller.Core.Tests
{
    using System;
    using IO;
    using Xunit;

    public class GivenBigEndianConverterWithInt32Values
    {
        [Fact]
        public void WhenConvertBytesRepresentingInt32MinValueThenValueIsEqualToInt32MinValue()
        {
            // arrange - calculate int32 min value
            var int32Bits = 32;
            var int32Min = Math.Pow(2, int32Bits) / 2 * -1;

            // arrange - bytes representing int32 min value
            var bytes = new byte[] { 128, 0, 0, 0 };

            // act - convert bytes to int32 value
            var int32Value = BigEndianConverter.ConvertBytesToInt32(bytes);

            // assert - int32 value is equal to min int32
            Assert.Equal(int32Min, int32Value);
            Assert.Equal(Int32.MinValue, int32Value);
        }

        [Fact]
        public void WhenConvertBytesRepresentingInt32MaxValueThenValueIsEqualToInt32MaxValue()
        {
            var int32Bits = 32;
            var int32Max = (Math.Pow(2, int32Bits) / 2) - 1;
            var bytes = new byte[] { 0x7f, 0xff, 0xff, 0xff };

            // act - convert bytes to int32 value
            var int32Value = BigEndianConverter.ConvertBytesToInt32(bytes);

            // assert - int32 value is equal to max int32
            Assert.Equal(int32Max, int32Value);
            Assert.Equal(Int32.MaxValue, int32Value);
        }

        [Fact]
        public void WhenConvertBytesRepresentingInt32Value511ThenValueIsEqual()
        {
            // arrange - bytes representing int32 value 511
            var bytes = new byte[] { 0, 0, 1, 0xff };

            // act - convert bytes to int32 value
            var intValue = BigEndianConverter.ConvertBytesToInt32(bytes);

            // assert - int32 value is equal to 511
            Assert.Equal(256 + 255, intValue);
        }

        [Fact]
        public void WhenConvertInt32Value511ThenBytesAreEqual()
        {
            // arrange - bytes representing int32 value 511
            var expectedBytes = new byte[]{0, 0, 1, 0xff};
            
            // act - convert int32 value to bytes
            var bytes = BigEndianConverter.ConvertInt32ToBytes(511);

            // assert - in32 value is equal to 511
            Assert.Equal(expectedBytes, bytes);
        }
        
        [Fact]
        public void WhenConvertInt32MaxValueThenBytesAreEqual()
        {
            // arrange - bytes representing int32 max value
            var expectedBytes = new byte[] { 0x7f, 0xff, 0xff, 0xff };

            // arrange - calculate int32 max value
            var int32Bits = 32;
            var int32Max = (int)((Math.Pow(2, int32Bits) / 2) - 1);
            
            // act - convert int32 value to bytes
            var bytes = BigEndianConverter.ConvertInt32ToBytes(int32Max);

            // assert - bytes are is equal to expected int32 max value bytes
            Assert.Equal(expectedBytes, bytes);
        }
        
        [Fact]
        public void WhenConvertInt32MinValueThenBytesAreEqual()
        {
            // arrange - bytes representing int32 min value
            var expectedBytes = new byte[] { 128, 0, 0, 0 };

            // arrange - calculate int32 min value
            var int32Bits = 32;
            var int32Min = (int)(Math.Pow(2, int32Bits) / 2 * -1);

            // act - convert int32 value to bytes
            var bytes = BigEndianConverter.ConvertInt32ToBytes(int32Min);

            // assert - bytes are is equal to expected int32 max value bytes
            Assert.Equal(expectedBytes, bytes);
        }
    }
}