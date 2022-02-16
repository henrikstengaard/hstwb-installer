namespace HstWbInstaller.Imager.Core.PhysicalDrives
{
    using System.Collections.Generic;
    using System.Globalization;
    using System.IO;
    using System.Linq;
    using System.Text;
    using System.Threading.Tasks;
    using CsvHelper;
    using CsvHelper.Configuration;
    using Models;

    public static class WmicReader
    {
        public static IEnumerable<WmicDiskDrive> ParseWmicCsv(string csv)
        {
            using var csvReader = new CsvReader(new StreamReader(new MemoryStream(Encoding.UTF8.GetBytes(csv))),
                new CsvConfiguration(CultureInfo.InvariantCulture)
                {
                    Delimiter = ",",
                    Encoding = Encoding.UTF8
                });

            return csvReader.GetRecords<WmicDiskDrive>().ToList();
        }
    }
}