namespace HstWbInstaller.Core.IO.Info
{
    using System.IO;
    using System.Threading.Tasks;
    using Extensions;

    public static class DrawerData2Reader
    {
        public static async Task<DrawerData2> Read(Stream stream)
        {
            var ddFlags = await stream.ReadUInt32();
            var ddViewModes = await stream.ReadUInt16();

            return new DrawerData2
            {
                Flags = ddFlags,
                ViewModes = ddViewModes
            };
        }
    }
}