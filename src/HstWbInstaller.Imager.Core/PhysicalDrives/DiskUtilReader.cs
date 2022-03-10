namespace HstWbInstaller.Imager.Core.PhysicalDrives
{
    using System.Collections.Generic;
    using System.IO;
    using System.Linq;
    using Claunia.PropertyList;
    using Models;

    public static class DiskUtilReader
    {
        public static IEnumerable<string> ParseList(Stream stream)
        {
            var pList = PropertyListParser.Parse(stream) as NSDictionary;

            if (pList == null)
            {
                throw new IOException("Invalid plist");
            }
            
            var wholeDisks = pList.ObjectForKey("WholeDisks") as NSArray;

            if (wholeDisks == null)
            {
                throw new IOException("Invalid plist");
            }
            
            return wholeDisks.OfType<NSString>().Select(x => x.Content);
        }
        
        public static DiskUtilInfo ParseInfo(Stream stream)
        {
            var pList = PropertyListParser.Parse(stream) as NSDictionary;

            if (pList == null)
            {
                throw new IOException("Invalid plist");
            }
            
            var busProtocol = GetString(pList, "BusProtocol");
            var ioRegistryEntryName = GetString(pList, "IORegistryEntryName");
            var size = GetLongNumber(pList, "TotalSize");
            var deviceNode = GetString(pList, "DeviceNode");
            var mediaType = GetString(pList, "MediaType");

            return new DiskUtilInfo
            {
                BusProtocol = busProtocol,
                IoRegistryEntryName = ioRegistryEntryName,
                Size = size,
                DeviceNode = deviceNode,
                MediaType = mediaType
            };
        }

        private static string GetString(NSDictionary dict, string key)
        {
            var stringObject = dict.ObjectForKey(key) as NSString;

            return stringObject == null ? string.Empty : stringObject.Content;
        }
        
        private static long GetLongNumber(NSDictionary dict, string key)
        {
            var nsNumber = dict.ObjectForKey(key) as NSNumber;

            if (nsNumber == null)
            {
                return 0;
            }

            return !long.TryParse(nsNumber.ToString().Trim('\"'), out var longValue) ? 0 : longValue;
        }
    }
}