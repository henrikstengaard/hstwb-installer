namespace HstWbInstaller.Imager.GuiApp.Controllers
{
    using System;
    using System.Collections.Generic;
    using System.Linq;
    using System.Threading.Tasks;
    using Core;
    using Core.Commands;
    using HstWbInstaller.Core.IO.RigidDiskBlocks;
    using Microsoft.AspNetCore.Mvc;

    [ApiController]
    [Route("list")]
    public class ListController : ControllerBase
    {
        [HttpGet]
        public async Task<IEnumerable<MediaInfo>> Get()
        {
            var physicalDriveManager = PhysicalDriveManager.Create(true);
            var physicalDrives = await physicalDriveManager.GetPhysicalDrives();

            var commandHelper = new CommandHelper();
            var listCommand = new ListCommand(commandHelper, physicalDrives);
            IEnumerable<MediaInfo> mediaInfos = null;
            listCommand.ListRead += (sender, args) => { mediaInfos = args.MediaInfos; };

            var result = await listCommand.Execute();
            if (result.IsFaulted)
            {
                throw new Exception(result.Error.Message);
            }

            return mediaInfos.Concat(new[]
            {
                new MediaInfo
                {
                    Path = "fake",
                    DiskSize = 1024L * 1024 * 1000 * 16,
                    Model = "SanDisk 16GB",
                    IsPhysicalDrive = true,
                    RigidDiskBlock = new RigidDiskBlock
                    {
                        BlockSize = 512,
                        CylBlocks = 1008,
                        Cylinders = 7362,
                        DiskProduct = "HstWB 4GB       ",
                        DiskRevision = "0.4 ",
                        DiskSize = 3799498752L,
                        DiskVendor = "UAE     ",
                        Heads = 16,
                        HiCylinder = 7361,
                        PartitionBlocks = new[]
                        {
                            new PartitionBlock
                            {
                                BlocksPerTrack = 63,
                                BootPriority = 0,
                                DosType = new byte[] { 50, 44, 53, 3 },
                                DriveName = "DH0",
                                FileSystemBlockSize = 512,
                                HighCyl = 610,
                                LowCyl = 2,
                                Mask = 2147483646U,
                                MaxTransfer = 130560,
                                NumBuffer = 80,
                                PartitionSize = 314302464L,
                                PreAlloc = 0,
                                Reserved = 2,
                                Sectors = 1,
                                Surfaces = 16
                            },
                            new PartitionBlock
                            {
                                BlocksPerTrack = 63,
                                BootPriority = 0,
                                DosType = new byte[] { 50, 44, 53, 3 },
                                DriveName = "DH1",
                                FileSystemBlockSize = 512,
                                HighCyl = 7356,
                                LowCyl = 611,
                                Mask = 2147483646U,
                                MaxTransfer = 130560,
                                NumBuffer = 80,
                                PartitionSize = 3481583616L,
                                PreAlloc = 0,
                                Reserved = 2,
                                Sectors = 1,
                                Surfaces = 16
                            }
                        }
                    }
                }
            });
        }
    }
}