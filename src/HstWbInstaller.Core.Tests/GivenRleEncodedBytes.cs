namespace HstWbInstaller.Core.Tests
{
    using System.Collections.Generic;
    using System.Linq;
    using System.Text;
    using Xunit;

    public class GivenRleEncodedBytes
    {
        [Fact]
        public void Test()
        {
            var rldCompressedData = new byte[] { 0xc4, 0x61, 0xc2, 0x62, 0x63, 0x64, 0xc6, 0x65, 0x66 };
            var expected = Encoding.ASCII.GetBytes("aaaaabbbcdeeeeeeef");

            var t = Decompress(rldCompressedData).ToArray();
            
            Assert.Equal(expected, t);
        }

        public IEnumerable<byte> Decompress(IEnumerable<byte> data)
        {
            var dataList = data.ToList();
            var decompressedData = new List<byte>();

            for (var i = 0; i < dataList.Count; i++)
            {
                var value = dataList[i];

                if (value < 192)
                {
                    decompressedData.Add(value);
                }
                else if (i < dataList.Count)
                {
                    var rleValue = dataList[++i];
                    for (var r = 0; r < value - 191; r++)
                    {
                        decompressedData.Add(rleValue);
                    }
                }
            }

            return decompressedData;
        }

    }
}