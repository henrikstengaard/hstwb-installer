namespace HstWbInstaller.Imager.Core.Commands
{
    using System;
    using System.Collections.Generic;
    using System.IO;
    using System.Linq;
    using System.Threading.Tasks;
    using DiscUtils;
    using DiscUtils.Streams;
    using DiscUtils.Vhd;
    using HstWbInstaller.Core;
    using HstWbInstaller.Core.IO.RigidDiskBlocks;
    using Models;

    public class CommandHelper : ICommandHelper
    {
        public virtual Result<Media> GetReadableMedia(IEnumerable<IPhysicalDrive> physicalDrives, string path, bool allowPhysicalDrive = true)
        {
            var physicalDrive = physicalDrives.FirstOrDefault(x => x.Path.Equals(path, StringComparison.OrdinalIgnoreCase));

            if (!allowPhysicalDrive && physicalDrive != null)
            {
                return new Result<Media>(new Error("Physical drive is not allowed"));
            }
            
            if (physicalDrive != null)
            {
                return new Result<Media>(new Media(path, physicalDrive.Model, Media.MediaType.Raw, true, physicalDrive.Open()));
            }

            if (string.IsNullOrWhiteSpace(path) || !File.Exists(path))
            {
                return new Result<Media>(new PathNotFoundError($"Path '{path ?? "null"}' not found", nameof(path)));
            }
            
            if (string.IsNullOrWhiteSpace(path) || !File.Exists(path))
            {
                return new Result<Media>(new PathNotFoundError($"Path '{path ?? "null"}' not found", nameof(path)));
            }

            var model = Path.GetFileName(path);
            if (!IsVhd(path))
            {
                return new Result<Media>(new Media(path, model, Media.MediaType.Raw, false, File.Open(path, FileMode.Open, FileAccess.Read)));
            }

            DiscUtils.Containers.SetupHelper.SetupContainers();
            DiscUtils.FileSystems.SetupHelper.SetupFileSystems();
            var vhdDisk = VirtualDisk.OpenDisk(path, FileAccess.Read);
            vhdDisk.Content.Position = 0;
            return new Result<Media>(new VhdMedia(path, model, Media.MediaType.Vhd, false, vhdDisk));
        }

        public virtual Stream CreateWriteableStream(string path)
        {
            return File.Open(path, FileMode.Create, FileAccess.ReadWrite, FileShare.ReadWrite);
        }

        public virtual Result<Media> GetWritableMedia(IEnumerable<IPhysicalDrive> physicalDrives, string path, long? size = null, bool allowPhysicalDrive = true)
        {
            var physicalDrive = physicalDrives.FirstOrDefault(x => x.Path.Equals(path, StringComparison.OrdinalIgnoreCase));

            if (!allowPhysicalDrive && physicalDrive != null)
            {
                return new Result<Media>(new Error("Physical drive is not allowed"));
            }
            
            if (physicalDrive != null)
            {
                physicalDrive.SetWritable(true);
                return new Result<Media>(new Media(path, physicalDrive.Model, Media.MediaType.Raw, true, physicalDrive.Open()));
            }

            if (string.IsNullOrWhiteSpace(path))
            {
                throw new ArgumentNullException(path);
            }

            var destDir = Path.GetDirectoryName(path);

            if (!string.IsNullOrEmpty(destDir) && !Directory.Exists(destDir))
            {
                Directory.CreateDirectory(destDir);
            }

            var stream = CreateWriteableStream(path);

            var model = Path.GetFileName(path);
            if (!IsVhd(path))
            {
                return new Result<Media>(new Media(path, model, Media.MediaType.Raw, false, stream));
            }

            if (size == null)
            {
                throw new ArgumentNullException(nameof(size), "Size required for vhd");
            }

            var vhdDisk = Disk.InitializeDynamic(stream, Ownership.None, GetVhdSize(size.Value));
            return new Result<Media>(new VhdMedia(path, model, Media.MediaType.Vhd, false, vhdDisk, stream));
        }

        // public virtual Media GetWritableMedia(IEnumerable<IPhysicalDrive> physicalDrives, string path, long size, bool allowPhysicalDrive = true)
        // {
        //     var physicalDrive = physicalDrives.FirstOrDefault(x => x.Path.Equals(path, StringComparison.OrdinalIgnoreCase));
        //
        //     if (!allowPhysicalDrive && physicalDrive != null)
        //     {
        //         throw new ArgumentException("Physical drive is not allowed");
        //     }
        //     
        //     if (physicalDrive != null)
        //     {
        //         return new Media(path, physicalDrive.Model, Media.MediaType.Raw, true, physicalDrive.Open());
        //     }
        //
        //     if (string.IsNullOrWhiteSpace(path))
        //     {
        //         throw new ArgumentNullException(path);
        //     }
        //
        //     var destDir = Path.GetDirectoryName(path);
        //
        //     if (!string.IsNullOrEmpty(destDir) && !Directory.Exists(destDir))
        //     {
        //         Directory.CreateDirectory(destDir);
        //     }
        //
        //     var stream = CreateWriteableStream(path);
        //
        //     var model = Path.GetFileName(path);
        //     if (!IsVhd(path))
        //     {
        //         return new Media(path, model, Media.MediaType.Raw, false, stream);
        //     }
        //
        //     var vhdDisk = Disk.InitializeDynamic(stream, Ownership.None, GetVhdSize(size));
        //     return new VhdMedia(path, model, Media.MediaType.Vhd, false, vhdDisk, stream);
        // }
        
        public virtual long GetVhdSize(long size)
        {
            // vhd size dividable by 512
            return size % 512 != 0 ? size + (512 - size % 512) : size;
        }

        public bool IsVhd(string path)
        {
            return path.EndsWith(".vhd", StringComparison.OrdinalIgnoreCase);
        }
        
        public virtual async Task<RigidDiskBlock> GetRigidDiskBlock(Stream stream)
        {
            try
            {
                stream.Seek(0, SeekOrigin.Begin);
            }
            catch (Exception)
            {
                return null;
            }

            RigidDiskBlock rigidDiskBlock;
            try
            {
                rigidDiskBlock = await RigidDiskBlockReader.Read(stream);
            }
            catch (Exception)
            {
                rigidDiskBlock = null;
            }
            
            try
            {
                stream.Seek(0, SeekOrigin.Begin);
            }
            catch (Exception)
            {
                return null;
            }
            
            return rigidDiskBlock;
        }
    }
}