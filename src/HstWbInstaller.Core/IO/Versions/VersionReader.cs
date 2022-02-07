namespace HstWbInstaller.Core.IO.Versions
{
    using System.IO;
    using System.Text;
    using System.Text.RegularExpressions;
    using System.Threading.Tasks;
    using Extensions;

    // https://aminet.net/package/util/sys/Ver
    public static class VersionReader
    {
        // "$VER: <name> <version>.<revision> (dd.mm.yy)"
        private static readonly Regex
            VersionRegex = new("\\$VER:\\s+([^\\s]+)\\s+(\\d+)\\.(\\d+)",
                RegexOptions.Compiled | RegexOptions.IgnoreCase);

        private static readonly Regex
            DateRegex = new("\\((\\d+)\\.(\\d+)\\.(\\d+)\\)", RegexOptions.Compiled | RegexOptions.IgnoreCase);

        public static async Task<string> Read(Stream stream)
        {
            var versionIndex = await stream.Find(Encoding.ASCII.GetBytes("$VER"));

            if (versionIndex == -1)
            {
                return null;
            }

            if (stream.Seek(versionIndex, SeekOrigin.Begin) != versionIndex)
            {
                return null;
            }

            return await stream.ReadNullTerminatedString();
        }

        public static FileVersion Parse(string version)
        {
            var versionMatch = VersionRegex.Match(version);

            if (!versionMatch.Success)
            {
                return null;
            }

            int.TryParse(versionMatch.Groups[2].Value, out var versionValue);
            int.TryParse(versionMatch.Groups[3].Value, out var revisionValue);

            var fileVersion = new FileVersion
            {
                Name = versionMatch.Groups[1].Value,
                Version = versionValue,
                Revision = revisionValue
            };
            
            var dateMatch = DateRegex.Match(version);

            if (!dateMatch.Success)
            {
                return fileVersion;
            }
            
            int.TryParse(dateMatch.Groups[1].Value, out var dateDayValue);
            int.TryParse(dateMatch.Groups[2].Value, out var dateMonthValue);
            int.TryParse(dateMatch.Groups[3].Value, out var dateYearValue);

            fileVersion.DateDay = dateDayValue;
            fileVersion.DateMonth = dateMonthValue;
            fileVersion.DateYear = dateYearValue;

            return fileVersion;
        }
    }
}