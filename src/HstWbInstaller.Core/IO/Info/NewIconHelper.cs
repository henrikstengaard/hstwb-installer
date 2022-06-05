namespace HstWbInstaller.Core.IO.Info
{
    using System.Linq;
    using SixLabors.ImageSharp;
    using SixLabors.ImageSharp.PixelFormats;

    public static class NewIconHelper
    {
        public static Image<Rgba32> ConvertToImage(NewIcon newIcon)
        {
            var pixelData = new byte[newIcon.Width * newIcon.Height * 4];

            var pixelDataOffset = 0;
            var imagePixelsOffset = 0;
            for (var y = 0; y < newIcon.Height; y++)
            {
                for (var x = 0; x < newIcon.Width; x++)
                {
                    var pixel = newIcon.ImagePixels[imagePixelsOffset++];
                    var color = newIcon.Palette[pixel];

                    pixelData[pixelDataOffset] = color[0]; // r
                    pixelData[pixelDataOffset + 1] = color[1]; // g
                    pixelData[pixelDataOffset + 2] = color[2]; // b
                    pixelData[pixelDataOffset + 3] = color[3]; // a

                    pixelDataOffset += 4;
                }
            }

            return Image.LoadPixelData<Rgba32>(pixelData, newIcon.Width, newIcon.Height);
        }

        public static void SetNewIconImage(DiskObject diskObject, int imageNumber, NewIcon newIcon)
        {
            var imageHeader = $"IM{imageNumber}=";

            if (diskObject.ToolTypes == null)
            {
                diskObject.ToolTypesPointer = 1;
                diskObject.ToolTypes = new ToolTypes();
            }
            
            var textDatas = diskObject.ToolTypes.TextDatas
                .Where(x => x.Data.Length >= 4 && !AmigaTextHelper.GetString(x.Data, 0, 4).Equals(imageHeader)).ToList();
            
            var newIconHeaderBytes = AmigaTextHelper.GetBytes(Constants.NewIcon.Header).Concat(new byte[]{0});
            var newIconHeaderTextData = textDatas.FirstOrDefault(x => x.Data.SequenceEqual(newIconHeaderBytes));
            var hasNewIcons = newIconHeaderTextData != null;

            if (!hasNewIcons)
            {
                textDatas.Add(InfoHelper.CreateTextData(" "));
                newIconHeaderTextData = InfoHelper.CreateTextData(Constants.NewIcon.Header);
                textDatas.Add(newIconHeaderTextData);
            }
            
            var encoder = new NewIconToolTypesEncoder(imageNumber, newIcon.Width, newIcon.Height, newIcon.Depth,
                newIcon.Transparent);
            encoder.EncodePalette(newIcon.Palette);
            encoder.EncodeImage(newIcon.ImagePixels);

            var newIconHeaderIndex = textDatas.IndexOf(newIconHeaderTextData);
            if (newIconHeaderIndex <= 0 && imageNumber == 1)
            {
                textDatas.InsertRange(newIconHeaderIndex + 1, encoder.GetToolTypes());
            }
            else
            {
                textDatas.AddRange(encoder.GetToolTypes());
            }
            
            diskObject.ToolTypes.TextDatas = textDatas;
        }
    }
}