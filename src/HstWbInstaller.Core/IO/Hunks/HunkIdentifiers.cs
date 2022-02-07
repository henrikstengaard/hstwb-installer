namespace HstWbInstaller.Core.IO.Hunks
{
    public static class HunkIdentifiers
    {
        /// <summary>
        /// Hunk header
        /// </summary>
        public const uint Header = 0x3F3;
        
        /// <summary>
        /// Hunk code
        /// </summary>
        public const uint Code = 0x3E9;

        /// <summary>
        /// Hunk reloc32
        /// </summary>
        public const uint ReLoc32 = 0x3EC;

        /// <summary>
        /// Hunk end
        /// </summary>
        public const uint End = 0x3F2;
    }
}