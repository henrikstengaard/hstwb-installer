namespace HstWbInstaller.Core.IO.Pfs3
{
    using System;

    public static class GeometryHelper
    {
        private static readonly long[][] schijf = { 
            new long[]{20480,20},
            new long[]{51200,30},
            new long[]{512000,40},
            new long[]{1048567,50},
            new long[]{99999999,70}
        };
    
        public static long CalcNumReserved(globaldata g, uint resblocksize)
        {
            long temp, taken, i;

            temp = g.TotalSectors * (g.blocksize / 128);
            temp /= resblocksize/128;
            taken = 0;

            for (i=0; temp > schijf[i][0]; i++)
            {
                taken += schijf[i][0]/schijf[i][1];
                temp -= schijf[i][0];
            }
            taken += temp/schijf[i][1];
            taken += 10;
            taken = Math.Min(Constants.MAXNUMRESERVED, taken);
            taken = (taken + 31) & ~0x1f;		/* multiple of 32 */

            return taken;
        }        
    }
}