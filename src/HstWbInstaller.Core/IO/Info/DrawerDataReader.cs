namespace HstWbInstaller.Core.IO.Info
{
    using System.IO;
    using System.Threading.Tasks;
    using Extensions;

    public static class DrawerDataReader
    {
        public static async Task<DrawerData> Read(Stream stream)
        {
            var leftEdge = await stream.ReadInt16();
            var topEdge = await stream.ReadInt16();
            var width = await stream.ReadInt16();
            var height = await stream.ReadInt16();
            var detailPen = (byte)stream.ReadByte();
            var blockPen = (byte)stream.ReadByte();
            var idcmpFlags = await stream.ReadUInt32();
            var flags = await stream.ReadUInt32();
            var firstGadget = await stream.ReadUInt32();
            var checkMark = await stream.ReadUInt32();
            var title = await stream.ReadUInt32();
            var screen = await stream.ReadUInt32();
            var bitMap = await stream.ReadUInt32();
            var minWidth = await stream.ReadInt16();
            var minHeight = await stream.ReadInt16();
            var maxWidth = await stream.ReadUInt16();
            var maxHeight = await stream.ReadUInt16();
            var type = await stream.ReadUInt16();
            var currentX = await stream.ReadInt32();
            var currentY = await stream.ReadInt32();

            return new DrawerData
            {
                LeftEdge = leftEdge,
                TopEdge = topEdge,
                Width = width,
                Height = height,
                DetailPen = detailPen,
                BlockPen = blockPen,
                IdcmpFlags = idcmpFlags,
                Flags = flags,
                FirstGadget = firstGadget,
                CheckMark = checkMark,
                Title = title,
                Screen = screen,
                BitMap = bitMap,
                MinWidth = minWidth,
                MinHeight = minHeight,
                MaxWidth = maxWidth,
                MaxHeight = maxHeight,
                Type = type,
                CurrentX = currentX,
                CurrentY = currentY
            };
        }
    }
}