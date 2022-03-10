namespace HstWbInstaller.Imager.Core.Tests
{
    using Xunit;

    public class GivenDiscUtilsInternalUtilities
    {
        [Fact]
        public void WhenCombinePathsThenPathIsIncorrectForUnixPath()
        {
            // test confirms CombinePaths method in
            // https://github.com/DiscUtils/DiscUtils/blob/develop/Library/DiscUtils.Core/Internal/Utilities.cs
            // incorrectly uses backslash for unix paths
            
            var directoryName = "/Users/testuser/Documents";
            var fileName = "hello.txt";

            var path = CombinePaths(directoryName, fileName);
            
            Assert.Equal("/Users/testuser/Documents\\hello.txt", path);
        }
        
        public static string CombinePaths(string a, string b)
        {
            if (string.IsNullOrEmpty(a) || (b.Length > 0 && b[0] == '\\'))
            {
                return b;
            }
            if (string.IsNullOrEmpty(b))
            {
                return a;
            }
            return a.TrimEnd('\\') + '\\' + b.TrimStart('\\');
        }
    }
}