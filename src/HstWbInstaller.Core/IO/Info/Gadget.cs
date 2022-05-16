namespace HstWbInstaller.Core.IO.Info
{
    public class Gadget
    {
        public uint NextPointer { get; set; }
        public int LeftEdge { get; set; }
        public int TopEdge { get; set; }
        public int Width { get; set; }
        public int Height { get; set; }
        public int Flags { get; set; }
        public int Activation { get; set; }
        public ushort GadgetType { get; set; }
        public uint GadgetRenderPointer { get; set; }
        public uint SelectRenderPointer { get; set; }
        public uint GadgetTextPointer { get; set; }
        public int MutualExclude { get; set; }
        public uint SpecialInfoPointer { get; set; }
        public ushort GadgetId { get; set; }
        public uint UserDataPointer { get; set; }
    }
}