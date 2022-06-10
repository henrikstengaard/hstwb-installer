namespace HstWbInstaller.Core.IO.Pfs3
{
    using System.Collections.Generic;
    using System.IO;
    using System.Threading.Tasks;
    using Blocks;

    public static class Volume
    {
/* make and fill in volume structure
 * uses g->geom!
 * returns 0 is fails
 */
        public static async Task<volumedata> MakeVolumeData(RootBlock rootblock, globaldata g)
        {
            //  struct volumedata *volume;
            //  struct MinList *list;
            //
            // ENTER("MakeVolumeData");

            // volume = AllocMemPR (sizeof(struct volumedata), g);
            var volume = new volumedata
            {
                rootblk = rootblock,
                rootblockchangeflag = false
            };

            /* lijsten initieren */
            // for (list = &volume.fileentries; list <= &volume->notifylist; list++)
            //     NewList((struct List *)list);
            // for (var node = volume.fileentries.First; list <= volume->notifylist; list++)
            // {
            //     list = node.Value;
            //     NewList((struct List *)list);
            // }
            

            /* andere gegevens invullen */
            volume.numsofterrors = 0;
            volume.diskstate = Constants.ID_VALIDATED;

            /* these could be put in rootblock @@ see also HD version */
            volume.numblocks = g.TotalSectors;
            volume.bytesperblock = (ushort)g.blocksize;
            volume.rescluster = (ushort)(rootblock.ReservedBlksize / volume.bytesperblock);

            /* Calculate minimum fake block size that keeps total block count less than 16M.
             * Workaround for programs (including WB) that calculate free space using
             * "in use * 100 / total" formula that overflows if in use is block count is larger
             * than 16M blocks with 512 block size. Used only in ACTION_INFO.
             */
            g.infoblockshift = 0;
            // if (DOSBase->dl_lib.lib_Version < 50)
            // {
            //     ushort blockshift = 0;
            //     var bpb = volume.bytesperblock;
            //     while (bpb > 512)
            //     {
            //         blockshift++;
            //         bpb >>= 1;
            //     }
            //
            //     // Calculate smallest safe fake block size, up to max 32k. (512=0,1024=1,..32768=6)
            //     while ((volume.numblocks >> blockshift) >= 0x02000000 && g.infoblockshift < 6)
            //     {
            //         g.infoblockshift++;
            //         blockshift++;
            //     }
            // }

            /* load rootblock extension (if it is present) */
            if (rootblock.Extension > 0 && rootblock.Options.HasFlag(RootBlock.DiskOptionsEnum.MODE_EXTENSION))
            {
                var rext = new CachedBlock(g);
            
                // rext = AllocBufmemR(sizeof(struct cachedblock) +rootblock->reserved_blksize, g);
                // memset(rext, 0, sizeof(struct cachedblock) +rootblock->reserved_blksize);
                IBlock blk;
                if ((blk = await Disk.RawRead<rootblockextension>(volume.rescluster, rootblock.Extension, g)) == null)
                {
                    throw new IOException("AFS_ERROR_READ_EXTENSION");
                }
                else
                {
                    rext.blk = blk;
                    if (rext.blk.id == Constants.EXTENSIONID)
                    {
                        volume.rblkextension = rext;
                        rext.volume = volume;
                        rext.blocknr = rootblock.Extension;
                    }
                    else
                    {
                        throw new IOException("AFS_ERROR_EXTENSION_INVALID");
                    }
                }

            }
            else
            {
                volume.rblkextension = null;
            }

            return volume;
        }
        
/* free all resources (memory) taken by volume accept doslist
** it is assumed all this data can be discarded (not checked here!)
** it is also assumed this volume is no part of any volumelist
*/
        public static void FreeVolumeResources(volumedata volume, globaldata g)
        {
            // ENTER("Free volume resources");

            if (volume != null)
            {
                FreeUnusedResources (volume, g);
// #if VERSION23
		// if (volume.rblkextension != null)
		// 	FreeBufmem (volume.rblkextension, g);
// #endif
// #if DELDIR
// 	//	if (g->deldirenabled)
// 	//		FreeBufmem (volume->deldir, g);
// #endif
                // FreeBufmem (volume->rootblk, g);
                // FreeMemP (volume, g);
            }

            // EXIT("FreeVolumeResources");
        }
        
        public static void FreeUnusedResources(volumedata volume, globaldata g)
        {
            // struct MinList *list;
            // struct MinNode *node, *next;

            // ENTER("FreeUnusedResources");

            /* check if volume passed */
            if (volume == null)
                return;

            /* start with anblks!, fileentries are to be kept! */
            // for (list = volume->anblks; list<=&volume->bmindexblks; list++)
            // {
            //     node = (struct MinNode *)HeadOf(list);
            //     while ((next = node->mln_Succ))
            //     {
            //         FlushBlock((struct cachedblock *)node, g);
            //         FreeLRU((struct cachedblock *)node);
            //         node = next;
            //     }
            // }
            foreach (var list in volume.anblks)
            {
                FreeMinList(list, g);
            }
            foreach (var list in volume.dirblks)
            {
                FreeMinList(list, g);
            }
            
            FreeMinList(volume.indexblks, g);
            FreeMinList(volume.bmblks, g);
            FreeMinList(volume.superblks, g);
            FreeMinList(volume.deldirblks, g);
            FreeMinList(volume.bmindexblks, g);
        }

        private static void FreeMinList(LinkedList<CachedBlock> list, globaldata g)
        {
            for (var node = list.First; node != null; node = node.Next)
            {
                Lru.FlushBlock(node.Value, g);
                Lru.FreeLRU(node.Value, g);
            }
        }
    }
}