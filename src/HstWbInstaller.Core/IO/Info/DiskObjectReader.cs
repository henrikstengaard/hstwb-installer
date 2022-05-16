namespace HstWbInstaller.Core.IO.Info
{
    using System.IO;
    using System.Threading.Tasks;
    using Extensions;

    public static class DiskObjectReader
    {
        public static async Task<DiskObject> Read(Stream stream)
        {
            var magic = await stream.ReadUInt16();

            if (magic != 0xe310)
            {
                throw new IOException("Invalid disk object magic");
            }

            var version = await stream.ReadUInt16();

            var diskObject = new DiskObject
            {
                Magic = magic,
                Version = version,
                Gadget = await GadgetReader.Read(stream),
                Type = stream.ReadByte()
            };

            stream.ReadByte(); // padding
            diskObject.DefaultToolPointer = await stream.ReadUInt32();
            diskObject.ToolTypesPointer = await stream.ReadUInt32();
            diskObject.CurrentX = await stream.ReadInt32();
            diskObject.CurrentY = await stream.ReadInt32();
            diskObject.DrawerDataPointer = await stream.ReadUInt32();
            diskObject.ToolWindowPointer = await stream.ReadUInt32();
            diskObject.StackSize = await stream.ReadInt32();

            if (diskObject.DrawerDataPointer != 0)
            {
                diskObject.DrawerData = await DrawerDataReader.Read(stream);
            }

            if (diskObject.Gadget.GadgetRenderPointer != 0)
            {
                diskObject.FirstImageData = await ImageDataReader.Read(stream);
            }

            if (diskObject.Gadget.SelectRenderPointer != 0)
            {
                diskObject.SecondImageData = await ImageDataReader.Read(stream);
            }
            
            if (diskObject.DefaultToolPointer != 0)
            {
                diskObject.DefaultTool = await TextDataReader.Read(stream);
            }

            if (diskObject.ToolTypesPointer != 0)
            {
                diskObject.ToolTypes = await ToolTypesReader.Read(stream);
            }

            if (diskObject.ToolWindowPointer != 0)
            {
                throw new IOException(
                    "ToolWindowPointer is defined. This is an extension, which was never implemented");
            }

            if (diskObject.DrawerDataPointer != 0 && diskObject.Gadget.UserDataPointer == 1)
            {
                diskObject.DrawerData2 = await DrawerData2Reader.Read(stream);
            }

            return diskObject;
        }
    }
}

    