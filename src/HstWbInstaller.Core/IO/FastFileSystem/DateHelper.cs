namespace HstWbInstaller.Core.IO.FastFileSystem
{
    using System;
    using System.IO;
    using System.Threading.Tasks;
    using Extensions;

    public static class DateHelper
    {

        public static DateTime ConvertToDate(int days, int minutes, int ticks)
        {
            return AmigaDate.AmigaEpocDate.AddDays(days).AddMinutes(minutes).AddMilliseconds(ticks);
        }

        public static AmigaDate ConvertToAmigaDate(DateTime date)
        {
            var diffDate = date - AmigaDate.AmigaEpocDate;
            var days = diffDate.Days;
            var minutes = diffDate.Hours * 60 + diffDate.Minutes;
            var ticks = Convert.ToInt32(diffDate.Milliseconds);

            return new AmigaDate
            {
                Days = days,
                Minutes = minutes,
                Ticks = ticks
            };
        }
        
        public static async Task<DateTime> ReadDate(Stream stream)
        {
            var days = await stream.ReadUInt32(); // days since 1 jan 78
            var minutes = await stream.ReadUInt32(); // minutes past midnight
            var ticks = await stream.ReadUInt32(); // ticks (1/50 sec) past last minute
            return AmigaDate.AmigaEpocDate.AddDays(days).AddMinutes(minutes).AddMilliseconds(ticks);
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
            
            var diffDate = date - AmigaDate.AmigaEpocDate;
            var days = (uint)diffDate.Days;
            var minutes = (uint)(diffDate.Hours * 60 + diffDate.Minutes);
            var ticks = (uint)Convert.ToInt32(diffDate.Milliseconds);
            
            await stream.WriteLittleEndianUInt32(days); // days since 1 jan 78
            await stream.WriteLittleEndianUInt32(minutes); // minutes past midnight
            await stream.WriteLittleEndianUInt32(ticks); // ticks (1/50 sec) past last minute
        }
    }
}