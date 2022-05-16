namespace HstWbInstaller.Core.IO.Info
{
    using System.IO;
    using System.Threading.Tasks;
    using Extensions;

    public static class GadgetReader
    {
        public static async Task<Gadget> Read(Stream stream)
        {
            var nextPointer = await stream.ReadUInt32();
            var leftEdge = await stream.ReadInt16();
            var topEdge = await stream.ReadInt16();
            var width = await stream.ReadInt16();
            var height = await stream.ReadInt16();
            var flags = await stream.ReadUInt16();
            var activation = await stream.ReadUInt16();
            var gadgetType = await stream.ReadUInt16();
            var gadgetRenderPointer = await stream.ReadUInt32();
            var selectRenderPointer = await stream.ReadUInt32();
            var gadgetTextPointer = await stream.ReadUInt32();
            var mutualExclude = await stream.ReadInt32();
            var specialInfoPointer = await stream.ReadUInt32();
            var gadgetId = await stream.ReadUInt16();
            var userDataPointer = await stream.ReadUInt32();

            return new Gadget
            {
                NextPointer = nextPointer,
                LeftEdge = leftEdge,
                TopEdge = topEdge,
                Width = width,
                Height = height,
                Flags = flags,
                Activation = activation,
                GadgetType = gadgetType,
                GadgetRenderPointer = gadgetRenderPointer,
                SelectRenderPointer = selectRenderPointer,
                GadgetTextPointer = gadgetTextPointer,
                MutualExclude = mutualExclude,
                SpecialInfoPointer = specialInfoPointer,
                GadgetId = gadgetId,
                UserDataPointer = userDataPointer
            };
        }
    }
}