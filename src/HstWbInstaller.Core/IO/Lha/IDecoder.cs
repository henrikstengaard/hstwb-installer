namespace HstWbInstaller.Core.IO.Lha
{
    public interface IDecoder
    {
        // https://github.com/jca02266/lha/blob/master/src/slide.c
        /* lh4 */
        //{decode_c_st1, decode_p_st1, decode_start_st1},
        
        ushort DecodeC(Huf huf);
        ushort DecodeP(Huf huf);
        void DecodeStart(Huf huf);
    }
}