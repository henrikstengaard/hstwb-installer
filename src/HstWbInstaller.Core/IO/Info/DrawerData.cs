namespace HstWbInstaller.Core.IO.Info
{
    public class DrawerData
    {
        public int LeftEdge { get; set; }
        public int TopEdge { get; set; }
        public int Width { get; set; }
        public int Height { get; set; }
        public byte DetailPen { get; set; }
        public byte BlockPen { get; set; }
        public uint IdcmpFlags { get; set; }
        public uint Flags { get; set; }
        public uint FirstGadget { get; set; }
        public uint CheckMark { get; set; }
        public uint Title { get; set; }
        public uint Screen { get; set; }
        public uint BitMap { get; set; }
        public short MinWidth { get; set; }
        public short MinHeight { get; set; }
        public ushort MaxWidth { get; set; }
        public ushort MaxHeight { get; set; }
        public ushort Type { get; set; }
        public int CurrentX { get; set; }
        public int CurrentY { get; set; }
    }
}