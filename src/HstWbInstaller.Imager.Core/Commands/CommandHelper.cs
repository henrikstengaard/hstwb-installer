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
    using HstWbInstaller.Core.IO.RigidDiskBlocks;
    using Models;

    public class CommandHelper : ICommandHelper
    {
        public virtual Media GetReadableMedia(IEnumerable<IPhysicalDrive> physicalDrives, string path, bool allowPhysicalDrive = true)
        {
            var physicalDrive = physicalDrives.FirstOrDefault(x => x.Path.Equals(path, StringComparison.OrdinalIgnoreCase));

            if (!allowPhysicalDrive && physicalDrive != null)
            {
                throw new ArgumentException("Physical drive is not allowed");
            }
            
            if (physicalDrive != null)
            {
                return new Media(path, Media.MediaType.Raw, true, physicalDrive.Open());
            }
            
            if (!IsVhd(path))
            {
                return new Media(path, Media.MediaType.Raw, false, File.Open(path, FileMode.Open, FileAccess.Read));
            }

            DiscUtils.Containers.SetupHelper.SetupContainers();
            DiscUtils.FileSystems.SetupHelper.SetupFileSystems();
            var vhdDisk = VirtualDisk.OpenDisk(path, FileAccess.Read);
            vhdDisk.Content.Position = 0;
            return new VhdMedia(path, Media.MediaType.Vhd, false, vhdDisk);
        }

        public virtual Stream CreateWriteableStream(string path)
        {
            return File.Open(path, FileMode.Create, FileAccess.ReadWrite, FileShare.ReadWrite);
        }

        public virtual Media GetWritableMedia(IEnumerable<IPhysicalDrive> physicalDrives, string path, long? size = null, bool allowPhysicalDrive = true)
        {
            var physicalDrive = physicalDrives.FirstOrDefault(x => x.Path.Equals(path, StringComparison.OrdinalIgnoreCase));

            if (!allowPhysicalDrive && physicalDrive != null)
            {
                throw new ArgumentException("Physical drive is not allowed");
            }
            
            if (physicalDrive != null)
            {
                return new Media(path, Media.MediaType.Raw, true, physicalDrive.Open());
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

            if (!IsVhd(path))
            {
                return new Media(path, Media.MediaType.Raw, false, stream);
            }

            if (size == null)
            {
                throw new ArgumentNullException(nameof(size), "Size required for vhd");
            }

            var vhdDisk = Disk.InitializeDynamic(stream, Ownership.None, GetVhdSize(size.Value));
            return new VhdMedia(path, Media.MediaType.Vhd, false, vhdDisk, stream);
        }

        public virtual Media GetWritableMedia(IEnumerable<IPhysicalDrive> physicalDrives, string path, long size, bool allowPhysicalDrive = true)
        {
            var physicalDrive = physicalDrives.FirstOrDefault(x => x.Path.Equals(path, StringComparison.OrdinalIgnoreCase));

            if (!allowPhysicalDrive && physicalDrive != null)
            {
                throw new ArgumentException("Physical drive is not allowed");
            }
            
            if (physicalDrive != null)
            {
                return new Media(path, Media.MediaType.Raw, true, physicalDrive.Open());
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

            if (!IsVhd(path))
            {
                return new Media(path, Media.MediaType.Raw, false, stream);
            }

            var vhdDisk = Disk.InitializeDynamic(stream, Ownership.None, GetVhdSize(size));
            return new VhdMedia(path, Media.MediaType.Vhd, false, vhdDisk, stream);
        }
        
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
            var buffer = new byte[16 * 512];
            try
            {
                stream.Seek(0, SeekOrigin.Begin);
                await stream.ReadAsync(buffer, 0, buffer.Length);
            }
            catch (Exception e)
            {
                throw new Exception($"Failed to read first {buffer.Length} bytes from stream: {e}");
            }

            RigidDiskBlock rigidDiskBlock = null;
            try
            {
                var rigidDiskBlockReader = new RigidDiskBlockReader(new MemoryStream(buffer));
                rigidDiskBlock = await rigidDiskBlockReader.Read(false);
                stream.Seek(0, SeekOrigin.Begin);
            }
            catch (Exception e)
            {
                throw new Exception($"Failed to rigid disk block from stream: {e}");
            }
            
            return rigidDiskBlock;
        }
    }
}