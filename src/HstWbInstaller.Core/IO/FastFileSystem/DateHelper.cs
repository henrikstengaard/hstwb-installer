namespace HstWbInstaller.Core.IO.FastFileSystem
{
    using System;
    using System.IO;
    using System.Threading.Tasks;
    using Extensions;

    public static class DateHelper
    {
        public static async Task WriteDate(Stream stream, DateTime date)
        {
            var amigaDate = new DateTime(1978, 1, 1, 0, 0, 0, DateTimeKind.Utc);
            var diffDate = date - amigaDate;
            var days = diffDate.Days;
            var minutes = diffDate.Hours * 60 + diffDate.Minutes;
            var ticks = Convert.ToInt32((double)50 / 60 * diffDate.Seconds);
            
            await stream.WriteLittleEndianInt32(days); // days since 1 jan 78
            await stream.WriteLittleEndianInt32(minutes); // minutes past midnight
            await stream.WriteLittleEndianInt32(ticks); // ticks (1/50 sec) past last minute
        }
    }
}