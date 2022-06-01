namespace HstWbInstaller.Core.IO.Info
{
    using System.IO;
    using System.Threading.Tasks;
    using Extensions;

    public static class ImageDataWriter
    {
        public static async Task Write(ImageData imageData, Stream stream)
        {
            await stream.WriteLittleEndianInt16(imageData.LeftEdge);
            await stream.WriteLittleEndianInt16(imageData.TopEdge);
            await stream.WriteLittleEndianInt16(imageData.Width);
            await stream.WriteLittleEndianInt16(imageData.Height);
            await stream.WriteLittleEndianInt16(imageData.Depth);

            await stream.WriteLittleEndianUInt32(imageData.ImageDataPointer);
            stream.WriteByte(imageData.PlanePick);
            stream.WriteByte(imageData.PlaneOnOff);
            await stream.WriteLittleEndianUInt32(imageData.NextPointer);
            await stream.WriteBytes(imageData.Data);
        }
    }
}