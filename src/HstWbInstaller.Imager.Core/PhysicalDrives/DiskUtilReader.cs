namespace HstWbInstaller.Imager.Core.PhysicalDrives
{
    using System.Collections.Generic;
    using System.IO;
    using Claunia.PropertyList;
    using Models;

    public static class DiskUtilReader
    {
        public static IEnumerable<DiskUtilDisk> ParseList(Stream stream)
        {
            var pList = PropertyListParser.Parse(stream) as NSDictionary;

            if (pList == null)
            {
                throw new IOException("Invalid diskutil info plist");
            }
            
            var allDisksAndPartitions = pList.ObjectForKey("AllDisksAndPartitions") as NSArray;

            if (allDisksAndPartitions == null)
            {
                throw new IOException("Invalid AllDisksAndPartitions key");
            }

            return ParseDisks(allDisksAndPartitions);
        }

        private static IEnumerable<DiskUtilDisk> ParseDisks(NSArray allDisksAndPartitions)
        {
            foreach (var item in allDisksAndPartitions)
            {
                var dict = item as NSDictionary;
                
                if (dict == null)
                {
                    throw new IOException("Invalid AllDisksAndPartitions item");
                }

                yield return ParseDisk(dict);
            }
        }

        private static DiskUtilDisk ParseDisk(NSDictionary dict)
        {
            var partitions = dict.ObjectForKey("Partitions") as NSArray;

            if (partitions == null)
            {
                throw new IOException("Invalid Partitions key");
            }
            
            return new DiskUtilDisk
            {
                DeviceIdentifier = GetString(dict, "DeviceIdentifier"),
                Partitions = ParsePartitions(partitions)
            };
        }

        private static IEnumerable<DiskUtilPartition> ParsePartitions(NSArray partitions)
        {
            foreach (var item in partitions)
            {
                var dict = item as NSDictionary;

                if (dict == null)
                {
                    throw new IOException("Invalid Partitions item");
                }

                yield return ParsePartition(dict);
            }
        }
        
        private static DiskUtilPartition ParsePartition(NSDictionary dict)
        {
            return new DiskUtilPartition
            {
                DeviceIdentifier = GetString(dict, "DeviceIdentifier")
            };
        }
        
        public static DiskUtilInfo ParseInfo(Stream stream)
        {
            var pList = PropertyListParser.Parse(stream) as NSDictionary;

            if (pList == null)
            {
                throw new IOException("Invalid diskutil info plist");
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

            if (stringObject == null)
            {
                throw new IOException($"Invalid {key} key");
            }

            return stringObject.Content;
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