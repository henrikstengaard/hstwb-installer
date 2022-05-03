namespace HstWbInstaller.Core.IO.FastFileSystem
{
    public interface IEntryBlock
    {
        int HeaderKey { get; set; }
        int Extension { get; set; }
        
        /// <summary>
        /// Hash table, points to same array as data blocks
        /// </summary>
        int[] HashTable { get; set; }
        
        /// <summary>
        /// Data blocks, points to same array as hash table
        /// </summary>
        int[] DataBlocks { get; set; }
    }
}