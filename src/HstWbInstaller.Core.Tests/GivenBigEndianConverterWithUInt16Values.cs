namespace HstWbInstaller.Core.Tests
{
    using System;
    using IO;
    using Xunit;

    public class GivenBigEndianConverterWithUInt16Values
    {
        [Fact]
        public void WhenConvertBytesRepresentingUInt16MinValueThenValueIsEqualToUInt16MinValue()
        {
            // arrange - uint16 min value
            ushort uint16Min = 0;

            // arrange - bytes representing uint16 min value
            var bytes = new byte[] { 0, 0 };

            // act - convert bytes to uint16 value
            var uint16Value = BigEndianConverter.ConvertBytesToUInt16(bytes);

            // assert - uint16 value is equal to min uint16
            Assert.Equal(uint16Min, uint16Value);
            Assert.Equal(ushort.MinValue, uint16Value);
        }

        [Fact]
        public void WhenConvertBytesRepresentingUInt16MaxValueThenValueIsEqualToUInt16MaxValue()
        {
            // arrange - calculate uint16 max value
            var int16Bits = 16;
            var uint16Max = Math.Pow(2, int16Bits) - 1;

            // arrange - bytes representing uint16 max value
            var bytes = new byte[] { 0xff, 0xff };

            // act - convert bytes to uint16 value
            var int16Value = BigEndianConverter.ConvertBytesToUInt16(bytes);

            // assert - uint16 value is equal to max uint16
            Assert.Equal(uint16Max, int16Value);
            Assert.Equal(UInt16.MaxValue, int16Value);
        }

        [Fact]
        public void WhenConvertBytesRepresentingUInt16Value511ThenValueIsEqual()
        {
            // arrange - bytes representing uint16 value 511
            var bytes = new byte[] { 1, 0xff };

            // act - convert bytes to uint16 value
            var uint16Value = BigEndianConverter.ConvertBytesToUInt16(bytes);

            // assert - uint16 value is equal to 511
            Assert.Equal(256U + 255, uint16Value);
        }

        [Fact]
        public void WhenConvertUInt16Value511ThenBytesAreEqual()
        {
            // arrange - bytes representing uint16 value 511
            var expectedBytes = new byte[]{1, 0xff};
            
            // act - convert uint16 value to bytes
            var bytes = BigEndianConverter.ConvertUInt16ToBytes(511);

            // assert - uint16 value is equal to 511
            Assert.Equal(expectedBytes, bytes);
        }
        
        [Fact]
        public void WhenConvertUInt16MaxValueThenBytesAreEqual()
        {
            // arrange - bytes representing uint16 max value
            var expectedBytes = new byte[] { 0xff, 0xff };

            // arrange - calculate uint16 max value
            var uint16Bits = 16;
            var uint16Max = (ushort)(Math.Pow(2, uint16Bits) - 1);
            
            // act - convert uint16 value to bytes
            var bytes = BigEndianConverter.ConvertUInt16ToBytes(uint16Max);

            // assert - bytes are is equal to expected uint16 max value bytes
            Assert.Equal(expectedBytes, bytes);
        }
        
        [Fact]
        public void WhenConvertUInt16MinValueThenBytesAreEqual()
        {
            // arrange - bytes representing uint16 min value
            var expectedBytes = new byte[] { 0, 0 };

            // arrange - calculate int16 min value
            const ushort uint16Min = 0;

            // act - convert uint16 value to bytes
            var bytes = BigEndianConverter.ConvertUInt16ToBytes(uint16Min);

            // assert - bytes are is equal to expected uint16 min value bytes
            Assert.Equal(expectedBytes, bytes);
        }
    }
}