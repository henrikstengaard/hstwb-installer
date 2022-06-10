namespace HstWbInstaller.Imager.Core.PhysicalDrives
{
    using System.Collections.Generic;
    using System.Globalization;
    using System.IO;
    using System.Linq;
    using System.Text;
    using System.Text.RegularExpressions;
    using System.Threading.Tasks;
    using CsvHelper;
    using CsvHelper.Configuration;
    using Models;

    public static class WmicReader
    {
        private static readonly Regex deviceIdRegex = new Regex("DeviceID=\"([^\"]*)\"", RegexOptions.IgnoreCase | RegexOptions.Compiled);
        
        public static IEnumerable<T> ParseWmicCsv<T>(string csv)
        {
            using var csvReader = new CsvReader(new StreamReader(new MemoryStream(Encoding.UTF8.GetBytes(csv))),
                new CsvConfiguration(CultureInfo.InvariantCulture)
                {
                    Delimiter = ",",
                    Encoding = Encoding.UTF8
                });

            return csvReader.GetRecords<T>().ToList();
        }

        public static IEnumerable<WmicDiskDriveToDiskPartition> ParseWmicDiskDriveToDiskPartitions(string csv)
        {
            foreach (var line in csv.Split('\n'))
            {
                var matches = deviceIdRegex.Matches(line);
                if (matches.Count != 2)
                {
                    continue;
                }

                yield return new WmicDiskDriveToDiskPartition
                {
                    Antecedent = matches[0].Groups[1].Value,
                    Dependent = matches[1].Groups[1].Value,
                };
            }
        }
        
        public static IEnumerable<WmicLogicalDiskToPartition> ParseWmicLogicalDiskToPartitions(string csv)
        {
            foreach (var line in csv.Split('\n'))
            {
                var matches = deviceIdRegex.Matches(line);
                if (matches.Count != 2)
                {
                    continue;
                }

                yield return new WmicLogicalDiskToPartition
                {
                    Antecedent = matches[0].Groups[1].Value,
                    Dependent = matches[1].Groups[1].Value,
                };
            }
        }
    }
}