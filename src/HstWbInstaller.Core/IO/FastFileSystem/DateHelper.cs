namespace HstWbInstaller.Core.IO.FastFileSystem
{
    using System;
    using System.IO;
    using System.Threading.Tasks;
    using Extensions;

    public static class DateHelper
    {
        private static readonly DateTime AmigaEpocDate = new(1978, 1, 1, 0, 0, 0, DateTimeKind.Utc);
            
        public static async Task<DateTime> ReadDate(Stream stream)
        {
            var days = await stream.ReadUInt32(); // days since 1 jan 78
            var minutes = await stream.ReadUInt32(); // minutes past midnight
            var ticks = await stream.ReadUInt32(); // ticks (1/50 sec) past last minute
            return AmigaEpocDate.AddDays(days).AddMinutes(minutes).AddSeconds(60 / 50 * ticks);
        }
        
        public static async Task WriteDate(Stream stream, DateTime date)
        {
            if (date == DateTime.MinValue)
            {
                await stream.WriteLittleEndianUInt32(0); // days since 1 jan 78
                await stream.WriteLittleEndianUInt32(0); // minutes past midnight
                await stream.WriteLittleEndianUInt32(0); // ticks (1/50 sec) past last minute
                return;
            }
            
            var diffDate = date - AmigaEpocDate;
            var days = (uint)diffDate.Days;
            var minutes = (uint)(diffDate.Hours * 60 + diffDate.Minutes);
            var ticks = (uint)Convert.ToInt32((double)50 / 60 * diffDate.Seconds);
            
            await stream.WriteLittleEndianUInt32(days); // days since 1 jan 78
            await stream.WriteLittleEndianUInt32(minutes); // minutes past midnight
            await stream.WriteLittleEndianUInt32(ticks); // ticks (1/50 sec) past last minute
        }
    }
}