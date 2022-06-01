namespace HstWbInstaller.Core.IO.Info
{
    using System.IO;
    using System.Threading.Tasks;
    using Extensions;

    public static class GadgetWriter
    {
        public static async Task Write(Gadget gadget, Stream stream)
        {
            await stream.WriteLittleEndianUInt32(gadget.NextPointer);
            await stream.WriteLittleEndianInt16(gadget.LeftEdge);
            await stream.WriteLittleEndianInt16(gadget.TopEdge);
            await stream.WriteLittleEndianInt16(gadget.Width);
            await stream.WriteLittleEndianInt16(gadget.Height);
            await stream.WriteLittleEndianUInt16(gadget.Flags);
            await stream.WriteLittleEndianUInt16(gadget.Activation);
            await stream.WriteLittleEndianUInt16(gadget.GadgetType);
            await stream.WriteLittleEndianUInt32(gadget.GadgetRenderPointer);
            await stream.WriteLittleEndianUInt32(gadget.SelectRenderPointer);
            await stream.WriteLittleEndianUInt32(gadget.GadgetTextPointer);
            await stream.WriteLittleEndianInt32(gadget.MutualExclude);
            await stream.WriteLittleEndianUInt32(gadget.SpecialInfoPointer);
            await stream.WriteLittleEndianUInt16(gadget.GadgetId);
            await stream.WriteLittleEndianUInt32(gadget.UserDataPointer);
        }
    }
}