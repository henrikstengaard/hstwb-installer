namespace HstWbInstaller.Core.Tests.AdfTests
{
    using System.Threading.Tasks;
    using IO.Adfs;
    using Xunit;

    public class GivenAdfCreator
    {
        [Fact]
        public async Task WhenCreateBlankAdfThenAdfIsValid()
        {
            var adfBytes = await Adf.CreateBlank("HstWB");

            Assert.Equal(901120, adfBytes.Length);
        }
    }
}