namespace HstWbInstaller.Core.IO.Pfs3
{
    using System.Collections.Generic;
    using Blocks;

    public class volumedata
    {
        // struct volumedata   *next;          /* volumechain                          */
        // struct volumedata   *prev;      
        public DeviceList devlist; /* <4A> device dos list                 */
        public RootBlock rootblk; /* the cached rootblock. Also in g.     */

//#if VERSION23
        public CachedBlock rblkextension; /* extended rblk, NULL if disabled*/
//#endif

        public LinkedList<lockentry> fileentries; /* all locks and open files             */
        public LinkedList<CachedBlock>[] anblks; //[Constants.HASHM_ANODE+1];   /* anode block hash table           */
        public LinkedList<CachedBlock>[] dirblks; //[Constants.HASHM_DIR+1];    /* dir block hash table             */
        public LinkedList<CachedBlock> indexblks; /* cached index blocks              */
        public LinkedList<CachedBlock> bmblks; /* cached bitmap blocks                 */
        public LinkedList<CachedBlock> superblks; /* cached super blocks					*/
        public LinkedList<CachedBlock> deldirblks; /* cached deldirblocks					*/
        public LinkedList<CachedBlock> bmindexblks; /* cached bitmap index blocks           */
        public LinkedList<string> anodechainlist; /* list of cached anodechains           */
        public LinkedList<string> notifylist; /* list of notifications                */

        public bool rootblockchangeflag; /* indicates if rootblock dirty         */
        public short numsofterrors; /* number of soft errors on this disk   */
        public short diskstate; /* normally ID_VALIDATED                */
        public long numblocks; /* total number of blocks               */
        public ushort bytesperblock; /* blok size (datablocks)               */
        public ushort rescluster; /* reserved blocks cluster              */

        public volumedata()
        {
            fileentries = new LinkedList<lockentry>();
            anblks = new LinkedList<CachedBlock>[Constants.HASHM_ANODE + 1];
            dirblks = new LinkedList<CachedBlock>[Constants.HASHM_DIR + 1];
            indexblks = new LinkedList<CachedBlock>();
            bmblks = new LinkedList<CachedBlock>();
            superblks = new LinkedList<CachedBlock>();
            deldirblks = new LinkedList<CachedBlock>();
            bmindexblks = new LinkedList<CachedBlock>();
            anodechainlist = new LinkedList<string>();
            notifylist = new LinkedList<string>();

            for (var i = 0; i < anblks.Length; i++)
            {
                anblks[i] = new LinkedList<CachedBlock>();
            }
            
            for (var i = 0; i < dirblks.Length; i++)
            {
                dirblks[i] = new LinkedList<CachedBlock>();
            }
        }
    }
}