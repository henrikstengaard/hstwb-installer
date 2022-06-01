namespace HstWbInstaller.Core.IO.Info
{
    using System.IO;
    using System.Threading.Tasks;
    using Extensions;

    public static class DrawerData2Writer
    {
        public static async Task Write(DrawerData2 drawerData2, Stream stream)
        {
            await stream.WriteLittleEndianUInt32(drawerData2.Flags);
            await stream.WriteLittleEndianUInt16(drawerData2.ViewModes);
        }
    }
}