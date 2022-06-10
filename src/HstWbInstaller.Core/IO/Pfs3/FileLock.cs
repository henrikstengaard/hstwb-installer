namespace HstWbInstaller.Core.IO.Pfs3
{
    /// <summary>
    /// Amiga dosextens.h file lock
    /// </summary>
    public class FileLock
    {
        /* a lock structure, as returned by Lock() or DupLock() */
        // struct FileLock {
        //     BPTR		fl_Link;	/* bcpl pointer to next lock */
        //     LONG		fl_Key;		/* disk block number */
        //     LONG		fl_Access;	/* exclusive or shared */
        //     struct MsgPort *	fl_Task;	/* handler task's port */
        //     BPTR		fl_Volume;	/* bptr to DLT_VOLUME DosList entry */
        // };
        
        public int		fl_Link;	/* bcpl pointer to next lock */
        public int		fl_Key;		/* disk block number */
        public int		fl_Access;	/* exclusive or shared */
        //struct MsgPort *	fl_Task;	/* handler task's port */
        public int		fl_Volume;	/* bptr to DLT_VOLUME DosList entry */
    }
}