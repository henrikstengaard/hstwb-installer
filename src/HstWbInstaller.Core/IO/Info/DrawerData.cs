namespace HstWbInstaller.Core.IO.Info
{
    public class DrawerData
    {
        public short LeftEdge { get; set; }
        public short TopEdge { get; set; }
        public short Width { get; set; }
        public short Height { get; set; }
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