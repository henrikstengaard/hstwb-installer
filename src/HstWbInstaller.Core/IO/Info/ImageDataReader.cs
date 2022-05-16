namespace HstWbInstaller.Core.IO.Info
{
    using System.IO;
    using System.Threading.Tasks;
    using Extensions;

    public static class ImageDataReader
    {
        public static async Task<ImageData> Read(Stream stream)
        {
            var leftEdge = await stream.ReadInt16();
            var topEdge = await stream.ReadInt16();
            var width = await stream.ReadInt16();
            var height = await stream.ReadInt16();
            var depth = await stream.ReadInt16();
            var imageDataPointer = await stream.ReadUInt32();
            var planePick = (byte)stream.ReadByte();
            var planeOnOff = (byte)stream.ReadByte();
            var nextPointer = await stream.ReadUInt32();

            var bytesPerRow = (width + 15) / 16 * 2;
            var imageByteSize = bytesPerRow * depth * height;

            var imageBytes = await stream.ReadBytes(imageByteSize);
            
            return new ImageData
            {
                LeftEdge = leftEdge,
                TopEdge = topEdge,
                Width = width,
                Height = height,
                Depth = depth,
                ImageDataPointer = imageDataPointer,
                PlanePick = planePick,
                PlaneOnOff = planeOnOff,
                NextPointer = nextPointer,
                Data = imageBytes
            };
        }
    }
}