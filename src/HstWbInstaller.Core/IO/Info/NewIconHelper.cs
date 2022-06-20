namespace HstWbInstaller.Core.IO.Info
{
    using System.Linq;
    using Images.Bitmap;
    using SixLabors.ImageSharp;
    using SixLabors.ImageSharp.PixelFormats;

    public static class NewIconHelper
    {

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
            
            // var encoder = new IConverterNewIconAsciiEncoder(imageNumber, newIcon);
            // var newIconTextDatas = encoder.Encode().ToList();
            var newIconTextDatas = NewIconToolTypesEncoder2.Encode(imageNumber, newIcon).ToList();

            var decoder = new NewIconToolTypesDecoder(newIconTextDatas);
            var n = decoder.Decode(imageNumber);
            var b = NewIconDecoder.DecodeToBitmap(n);
            var stream = System.IO.File.OpenWrite("decoded.bmp");
            BitmapImageWriter.Write(stream, b);
            
            

            var newIconHeaderIndex = textDatas.IndexOf(newIconHeaderTextData);
            if (newIconHeaderIndex <= 0 && imageNumber == 1)
            {
                textDatas.InsertRange(newIconHeaderIndex + 1, newIconTextDatas);
            }
            else
            {
                textDatas.AddRange(newIconTextDatas);
            }
            
            diskObject.ToolTypes.TextDatas = textDatas;
        }
    }
}