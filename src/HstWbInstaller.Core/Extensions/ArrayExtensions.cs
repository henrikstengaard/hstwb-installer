namespace HstWbInstaller.Core.Extensions
{
    using System;
    using System.Collections.Generic;
    using System.Linq;

    public static class ArrayExtensions
    {
        public static T[] Slice<T>(this T[] source, int index, int length)
        {       
            var slice = new T[length];
            Array.Copy(source, index, slice, 0, length);
            return slice;
        }
        
        public static IEnumerable<IEnumerable<T>> ChunkBy<T>(this IEnumerable<T> source, int chunkSize) 
        {
            return source
                .Select((x, i) => new { Index = i, Value = x })
                .GroupBy(x => x.Index / chunkSize)
                .Select(x => x.Select(v => v.Value).ToList())
                .ToList();
        }
        
        public static int Search(this byte[] data, byte[] pattern)
        {
            var maxFirstCharSlot = data.Length - pattern.Length + 1;
            for (var i = 0; i < maxFirstCharSlot; i++)
            {
                if (data[i] != pattern[0]) // compare only first byte
                    continue;
        
                // found a match on first byte, now try to match rest of the pattern
                for (var j = pattern.Length - 1; j >= 1; j--) 
                {
                    if (data[i + j] != pattern[j]) break;
                    if (j == 1) return i;
                }
            }
            return -1;
        }
    }
}