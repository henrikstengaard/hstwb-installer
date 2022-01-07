namespace HstWbInstaller.Core.Tests
{
    public abstract class SectorTestBase
    {
        protected const int SectorSize = 512;
        
        protected byte[] CreateSector(byte data = 0)
        {
            var sector = new byte[SectorSize];

            if (data == 0) return sector;
            
            sector[0] = data;
            sector[SectorSize - 1] = data;

            return sector;
        }
    }
}