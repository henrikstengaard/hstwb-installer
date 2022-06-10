namespace HstWbInstaller.Core.IO.Info
{
    using System.Collections.Generic;

    public static class AmigaOs31Palette
    {
        /// <summary>
        /// Amiga OS 3.1 4 color setting
        /// </summary>
        public static readonly IList<byte[]> FourColors = new List<byte[]>
        {
            new byte[] { 170, 170, 170, 255 },
            new byte[] { 0, 0, 0, 255 },
            new byte[] { 255, 255, 255, 255 },
            new byte[] { 102, 136, 187, 255 },
        };

        /// <summary>
        /// Amiga OS 3.1 multicolor setting
        /// </summary>
        public static readonly IList<byte[]> Multicolor = new List<byte[]>
        {
            new byte[] { 170, 170, 170, 255 },
            new byte[] { 0, 0, 0, 255 },
            new byte[] { 255, 255, 255, 255 },
            new byte[] { 102, 136, 187, 255 },
                    
            new byte[] { 238, 68, 68, 255 },
            new byte[] { 85, 221, 85, 255 },
            new byte[] { 0, 68, 221, 255 },
            new byte[] { 238, 153, 0, 255 },
        };
        
        /// <summary>
        /// Amiga OS 3.1 full palette
        /// </summary>
        public static readonly IList<byte[]> FullPalette = new List<byte[]>
        {
            new byte[] { 153, 153, 153, 255 },
            new byte[] { 17, 17, 17, 255 },
            new byte[] { 238, 238, 238, 255 },
            new byte[] { 75, 105, 175, 255 },
                    
            new byte[] { 119, 119, 119, 255 },
            new byte[] { 187, 187, 187, 255 },
            new byte[] { 204, 170, 119, 255 },
            new byte[] { 221, 102, 153, 255 },
                    
            new byte[] { 102, 34, 0, 255 },
            new byte[] { 238, 85, 0, 255 },
            new byte[] { 153, 255, 17, 255 },
            new byte[] { 238, 187, 0, 255 },
                    
            new byte[] { 85, 85, 255, 255 },
            new byte[] { 153, 34, 255, 255 },
            new byte[] { 0, 255, 136, 255 },
            new byte[] { 204, 204, 204, 255 },
        };
    }
}