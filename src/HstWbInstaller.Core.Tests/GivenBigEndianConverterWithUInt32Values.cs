namespace HstWbInstaller.Core.Tests
{
    using System;
    using IO;
    using Xunit;

    public class GivenBigEndianConverterWithUInt32Values
    {
        [Fact]
        public void WhenConvertBytesRepresentingUInt32MinValueThenValueIsEqualToUInt32MinValue()
        {
            // arrange - uint32 min value
            ushort uint32Min = 0;

            // arrange - bytes representing uint32 min value
            var bytes = new byte[] { 0, 0, 0, 0 };

            // act - convert bytes to uint32 value
            var uint32Value = BigEndianConverter.ConvertBytesToUInt16(bytes);

            // assert - in32 value is equal to min int32
            Assert.Equal(uint32Min, uint32Value);
            Assert.Equal(uint.MinValue, uint32Value);
        }

        [Fact]
        public void WhenConvertBytesRepresentingUInt32MaxValueThenValueIsEqualToUInt32MaxValue()
        {
            var uint32Bits = 32;
            var uint32Max = Math.Pow(2, uint32Bits) - 1;
            
            var bytes = new byte[] { 0xff, 0xff, 0xff, 0xff };

            // act - convert bytes to uint32 value
            var uInt32Value = BigEndianConverter.ConvertBytesToUInt32(bytes);

            // assert - uin32 value is equal to max uint32
            Assert.Equal(uint32Max, uInt32Value);
        }


        [Fact]
        public void WhenConvertBytesRepresentingUInt32Value511ThenValueIsEqual()
        {
            // arrange - bytes representing uint32 value 511
            var bytes = new byte[] { 0, 0, 1, 0xff };

            // act - convert bytes to uint32 value
            var uint32Value = BigEndianConverter.ConvertBytesToUInt32(bytes);

            // assert - uin32 value is equal to 511
            Assert.Equal(256U + 255, uint32Value);
        }

        
        [Fact]
        public void WhenConvertUInt32Value511ThenBytesAreEqual()
        {
            // arrange - bytes representing uint32 value 511
            var expectedBytes = new byte[]{0, 0, 1, 0xff};
            
            // act - convert uint32 value to bytes
            var bytes = BigEndianConverter.ConvertUInt32ToBytes(511);

            // assert - in32 value is equal to 511
            Assert.Equal(expectedBytes, bytes);
        }
        
        [Fact]
        public void WhenConvertUInt32MaxValueThenBytesAreEqual()
        {
            // arrange - calculate uint32 max value
            var uint32Bits = 32;
            var uint32Max = (uint)(Math.Pow(2, uint32Bits) - 1);
            
            // arrange - bytes representing uint32 value 511
            var expectedBytes = new byte[]{0xff, 0xff, 0xff, 0xff};
            
            // act - convert uint32 value to bytes
            var bytes = BigEndianConverter.ConvertUInt32ToBytes(uint32Max);

            // assert - in32 value is equal to 511
            Assert.Equal(expectedBytes, bytes);
        }
    }
}