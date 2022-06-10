namespace HstWbInstaller.Core.Tests.CompressionTests
{
    using IO.Lha.Decode;
    using Xunit;

    public class GivenLzhHuffman
    {
        [Fact]
        public void WhenMakeHuffmanTableThenResultIsSuccess()
        {
            var huffman = new huffman
            {
                freq = new[]{1, 0, 2, 3, 1, 1, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
                tbl_bits = 16
            };
            var result = LzhHuffman.lzh_make_huffman_table(huffman);
            Assert.True(result);
        }
    }
}