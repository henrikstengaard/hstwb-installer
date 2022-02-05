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
    }
}