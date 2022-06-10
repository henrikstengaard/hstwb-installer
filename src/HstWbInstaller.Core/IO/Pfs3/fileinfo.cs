namespace HstWbInstaller.Core.IO.Pfs3
{
    using Blocks;

    public class fileinfo
    {
        /* FileInfo
        **
        ** Fileinfo wordt door FindFile opgeleverd. Bevat pointers die wijzen naar
        ** gecachede directoryblokken. Deze blokken mogen dus alleen uit de cache
        ** verwijderd worden als deze verwijzingen verwijderd zijn. Op 't ogenblik
        ** is het verwijderen van fileinfo's uit in gebruik zijnde fileentries
        ** niet toegestaan. Een fileinfo gevuld met {NULL, xxx} is een volumeinfo. Deze
        ** wordt in locks naar de rootdir gebruikt.
        ** Een *fileinfo van NULL verwijst naar de root van de current volume
        */
        public direntry direntry;      // pointer wijst naar direntry binnen gecached dirblock
        public CachedBlock dirblock;     // pointer naar gecached dirblock
    }
}