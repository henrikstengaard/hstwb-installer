namespace HstWbInstaller.Core.IO.Info
{
    public class ImageData
    {
        public short LeftEdge { get; set; }
        public short TopEdge { get; set; }
        public short Width { get; set; }
        public short Height { get; set; }
        public short Depth { get; set; }
        public uint ImageDataPointer { get; set; }
        public byte PlanePick { get; set; }
        public byte PlaneOnOff { get; set; }
        public uint NextPointer { get; set; }
        public byte[] Data { get; set; }
    }
}