namespace HstWbInstaller.Core.Tests
{
    using System;
    using IO;
    using Xunit;

    public class GivenBigEndianConverterWithInt16Values
    {
        [Fact]
        public void WhenConvertBytesRepresentingInt16MinValueThenValueIsEqualToInt16MinValue()
        {
            // arrange - calculate int16 min value
            var int16Bits = 16;
            var int16Min = Math.Pow(2, int16Bits) / 2 * -1;

            // arrange - bytes representing int16 min value
            var bytes = new byte[] { 128, 0 };

            // act - convert bytes to int16 value
            var int16Value = BigEndianConverter.ConvertBytesToInt16(bytes);

            // assert - int16 value is equal to min int16
            Assert.Equal(int16Min, int16Value);
            Assert.Equal(Int16.MinValue, int16Value);
        }

        [Fact]
        public void WhenConvertBytesRepresentingInt16MaxValueThenValueIsEqualToInt16MaxValue()
        {
            // arrange - calculate int16 max value
            var int16Bits = 16;
            var int16Max = (Math.Pow(2, int16Bits) / 2) - 1;

            // arrange - bytes representing int16 max value
            var bytes = new byte[] { 0x7f, 0xff };

            // act - convert bytes to int16 value
            var int16Value = BigEndianConverter.ConvertBytesToInt16(bytes);

            // assert - int16 value is equal to max int16
            Assert.Equal(int16Max, int16Value);
            Assert.Equal(Int16.MaxValue, int16Value);
        }

        [Fact]
        public void WhenConvertBytesRepresentingInt16Value511ThenValueIsEqual()
        {
            // arrange - bytes representing int16 value 511
            var bytes = new byte[] { 1, 0xff };

            // act - convert bytes to int16 value
            var int16Value = BigEndianConverter.ConvertBytesToInt16(bytes);

            // assert - int16 value is equal to 511
            Assert.Equal(256 + 255, int16Value);
        }

        [Fact]
        public void WhenConvertInt16Value511ThenBytesAreEqual()
        {
            // arrange - bytes representing int16 value 511
            var expectedBytes = new byte[]{1, 0xff};
            
            // act - convert int16 value to bytes
            var bytes = BigEndianConverter.ConvertInt16ToBytes(511);

            // assert - int16 value is equal to 511
            Assert.Equal(expectedBytes, bytes);
        }
        
        [Fact]
        public void WhenConvertInt16MaxValueThenBytesAreEqual()
        {
            // arrange - bytes representing int16 max value
            var expectedBytes = new byte[] { 0x7f, 0xff };

            // arrange - calculate int16 max value
            var int16Bits = 16;
            var int16Max = (short)((Math.Pow(2, int16Bits) / 2) - 1);
            
            // act - convert int16 value to bytes
            var bytes = BigEndianConverter.ConvertInt16ToBytes(int16Max);

            // assert - bytes are is equal to expected int16 max value bytes
            Assert.Equal(expectedBytes, bytes);
        }
        
        [Fact]
        public void WhenConvertInt16MinValueThenBytesAreEqual()
        {
            // arrange - bytes representing int16 min value
            var expectedBytes = new byte[] { 128, 0 };

            // arrange - calculate int16 min value
            var int16Bits = 16;
            var int16Min = (short)(Math.Pow(2, int16Bits) / 2 * -1);

            // act - convert int32 value to bytes
            var bytes = BigEndianConverter.ConvertInt16ToBytes(int16Min);

            // assert - bytes are is equal to expected int32 max value bytes
            Assert.Equal(expectedBytes, bytes);
        }
    }
}