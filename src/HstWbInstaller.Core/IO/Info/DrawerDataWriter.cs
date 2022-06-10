namespace HstWbInstaller.Core.IO.Info
{
    using System.IO;
    using System.Threading.Tasks;
    using Extensions;

    public static class DrawerDataWriter
    {
        public static async Task Write(DrawerData drawerData, Stream stream)
        {
            await stream.WriteLittleEndianInt16(drawerData.LeftEdge);
            await stream.WriteLittleEndianInt16(drawerData.TopEdge);
            await stream.WriteLittleEndianInt16(drawerData.Width);
            await stream.WriteLittleEndianInt16(drawerData.Height);
            stream.WriteByte(drawerData.DetailPen);
            stream.WriteByte(drawerData.BlockPen);
            await stream.WriteLittleEndianUInt32(drawerData.IdcmpFlags);
            await stream.WriteLittleEndianUInt32(drawerData.Flags);
            await stream.WriteLittleEndianUInt32(drawerData.FirstGadget);
            await stream.WriteLittleEndianUInt32(drawerData.CheckMark);
            await stream.WriteLittleEndianUInt32(drawerData.Title);
            await stream.WriteLittleEndianUInt32(drawerData.Screen);
            await stream.WriteLittleEndianUInt32(drawerData.BitMap);
            await stream.WriteLittleEndianInt16(drawerData.MinWidth);
            await stream.WriteLittleEndianInt16(drawerData.MinHeight);
            await stream.WriteLittleEndianUInt16(drawerData.MaxWidth);
            await stream.WriteLittleEndianUInt16(drawerData.MaxHeight);
            await stream.WriteLittleEndianUInt16(drawerData.Type);
            await stream.WriteLittleEndianInt32(drawerData.CurrentX);
            await stream.WriteLittleEndianInt32(drawerData.CurrentY);
        }
    }
}