namespace HstWbInstaller.Core.IO.Info
{
    using System.Collections.Generic;

    public static class NewIconToolTypesEncoder2
    {
        public static IEnumerable<TextData> Encode(int imageNumber, NewIcon newIcon)
        {
            var encoder = new NewIconAsciiEncoder(imageNumber, 8);

            // write new icon header
            encoder.Add((byte)(newIcon.Transparent ? 66 : 67));
            encoder.Add((byte)(0x21 + newIcon.Width));
            encoder.Add((byte)(0x21 + newIcon.Height));
            
            // write number of palette colors
            var colors = newIcon.Palette.Length;
            encoder.Add((byte)(0x21 + (colors >> 6)));
            encoder.Add((byte)(0x21 + (colors & 0x3f)));

            // encode palette
            foreach (var color in newIcon.Palette)
            {
                for (var c = 0; c < 3; c++)
                {
                    encoder.Encode(color[c]);
                }
            }
            
            encoder.Flush();
            
            encoder.SetBitsPerValue(newIcon.Depth);
            
            var offset = 0;
            for (var y = 0; y < newIcon.Height; y++)
            {
                for (var x = 0; x < newIcon.Width; x++)
                {
                    encoder.Encode(newIcon.ImagePixels[offset++]);
                }
            }
            
            encoder.Flush();

            return encoder.TextDatas;
        }
    }
}