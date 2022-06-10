// namespace HstWbInstaller.Core.IO.Pfs3
// {
//     using System.IO;
//     using System.Threading.Tasks;
//     using Blocks;
//
//     public static class DdSupport
//     {
//         /*
//      * Leave MODE_SLEEP
//      *
//      * Reload all essential blocks. References are restored by searching
//      * by anodenr in the directory identified by diranodenr (using FetchObject)
//      */
//         public static async Task Awake(globaldata g)
//         {
//             listentry le;
//             var volume = g.currentvolume;
//             // struct rootblock *rootblock;
//             // SIPTR error;
//
//             if (volume != null)
//             {
//                 /* reload current rootblock  */
//                 var rootblock = volume.rootblk;
//                 var buffer = await Disk.RawRead(rootblock.RblkCluster, Constants.ROOTBLOCK, g);
//                 rootblock = await RootBlockReader.Parse(buffer);
//
//                 /* reload rootblock extension */
//                 if (rootblock.Extension != 0 && (rootblock.Options.HasFlag(RootBlock.DiskOptionsEnum.MODE_EXTENSION)))
//                 {
//                     // RawRead((UBYTE *)&volume->rblkextension->blk, volume->rescluster, rootblock->extension, g);
//                     var blk = await Disk.RawRead<rootblockextension>(volume.rescluster, Constants.ROOTBLOCK+1, g);
//                     volume.rblkextension.blk = blk;
//                 }
//
//                 /* reload deldir */
//                 // if (rootblock->deldir && (rootblock->options & MODE_DELDIR))
//                 //	RawRead((UBYTE *)&volume->deldir->blk, volume->rescluster,
//                 //		rootblock->deldir, g);
//
//                 /* reconfigure modules */
//                 await Init.InitModules (volume, false, g);
//
//                 /* restore references */
//                 for (var node = Macro.HeadOf(volume.fileentries); node != null; node = node.Next)
//                 {
//                     le = node.Value;
//                     if (!IsVolumeEntry(le))
//                     {
//                         if (!FetchObject(le.diranodenr, le.anodenr, le.info, g))
//                             ErrorMsg(AFS_ERROR_UNSLEEP, NULL, g);  /*  -> kill, invalidate lock <- */
//
//                         if (Macro.IsFileEntry(le))
//                         {
//                             uint offset;
//                             var fe = le;
//
//                             /* restore anodechain and fe->currnode */
//                             if (!(fe.anodechain = await anodes.GetAnodeChain(fe.le.anodenr, g)))
//                                 ;   /* kill, invalidate */
// 				
//                             offset = fe.offset;
//                             fe.currnode = fe.anodechain.head;
//                             fe.offset = fe.blockoffset = fe.anodeoffset = 0;
//                             if (SeekInObject(fe, offset, OFFSET_BEGINNING, &error, g) == -1)
//                                 ErrorMsg(AFS_ERROR_UNSLEEP, NULL, g);  /* -> kill, invalidate */
//                         }
//                     }
//                 }
//             }
//
//             // --> prevent 'normal' reference-restore on loading
//             //  directory blocks
//
//             /* unset sleepmode */
//             // g->sleepmode = FALSE;
//
//             /* awake */
//             // g->DoCommand = NormalCommands;
//         }
//     }
// }