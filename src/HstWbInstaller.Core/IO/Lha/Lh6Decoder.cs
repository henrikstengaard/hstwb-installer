namespace HstWbInstaller.Core.IO.Lha
{
    public class Lh6Decoder : IDecoder
    {
        public ushort DecodeC(Huf huf)
        {
            return huf.decode_c_st1();
        }

        public ushort DecodeP(Huf huf)
        {
            return huf.decode_p_st1();
        }

        public void DecodeStart(Huf huf)
        {
            huf.decode_start_st1();
        }
    }
}