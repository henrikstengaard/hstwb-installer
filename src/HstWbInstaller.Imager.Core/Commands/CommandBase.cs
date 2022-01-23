namespace HstWbInstaller.Imager.Core.Commands
{
    using System;
    using System.Collections.Generic;
    using System.Linq;
    using System.Text.Json;
    using System.Threading.Tasks;
    using HstWbInstaller.Core;

    public abstract class CommandBase
    {
        protected static readonly JsonSerializerOptions JsonSerializerOptions = new()
        {
            WriteIndented = true
        };

        protected IPhysicalDrive GetPhysicalDrive(IEnumerable<IPhysicalDrive> physicalDrives, string path)
        {
            if (string.IsNullOrWhiteSpace(path))
            {
                throw new ArgumentNullException(nameof(path));
            }

            var physicalDrive =
                physicalDrives.FirstOrDefault(x =>
                    x.Path.Equals(path, StringComparison.OrdinalIgnoreCase));

            if (physicalDrive == null)
            {
                throw new ArgumentOutOfRangeException($"No physical drive with path '{path}'");
            }

            return physicalDrive;
        }

        // protected Media GetReadableMedia(IEnumerable<IPhysicalDrive> physicalDrives, string path, bool allowPhysicalDrive = true)
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
        //         return new Media(path, Media.MediaType.Raw, true, physicalDrive.Open());
        //     }
        //     
        //     if (!IsVhd(path))
        //     {
        //         return new Media(path, Media.MediaType.Raw, false, File.Open(path, FileMode.Open, FileAccess.Read));
        //     }
        //
        //     DiscUtils.Containers.SetupHelper.SetupContainers();
        //     DiscUtils.FileSystems.SetupHelper.SetupFileSystems();
        //     var vhdDisk = VirtualDisk.OpenDisk(path, FileAccess.Read);
        //     vhdDisk.Content.Position = 0;
        //     return new Media(path, Media.MediaType.Vhd, false, vhdDisk.Content);
        // }
        //
        // protected Media GetWritableMedia(IEnumerable<IPhysicalDrive> physicalDrives, string path, long size, bool allowPhysicalDrive = true)
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
        //         return new Media(path, Media.MediaType.Raw, true, physicalDrive.Open());
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
        //     var stream = File.Open(path, FileMode.Create, FileAccess.ReadWrite);
        //
        //     if (!IsVhd(path))
        //     {
        //         return new Media(path, Media.MediaType.Raw, false, stream);
        //     }
        //
        //     var vhdDisk = Disk.InitializeDynamic(stream, Ownership.None, GetVhdSize(size));
        //     return new Media(path, Media.MediaType.Vhd, false, vhdDisk.Content);
        // }

        // protected long GetVhdSize(long size)
        // {
        //     // vhd size dividable by 512
        //     return size % 512 != 0 ? size + (512 - size % 512) : size;
        // }
        //
        // protected bool IsVhd(string path)
        // {
        //     return path.EndsWith(".vhd", StringComparison.OrdinalIgnoreCase);
        // }

        // protected async Task<RigidDiskBlock> GetRigidDiskBlock(Stream stream)
        // {
        //     var buffer = new byte[16 * 512];
        //     try
        //     {
        //         stream.Seek(0, SeekOrigin.Begin);
        //         await stream.ReadAsync(buffer, 0, buffer.Length);
        //     }
        //     catch (Exception e)
        //     {
        //         throw new Exception($"Failed to read first {buffer.Length} bytes from stream: {e}");
        //     }
        //
        //     RigidDiskBlock rigidDiskBlock = null;
        //     try
        //     {
        //         var rigidDiskBlockReader = new RigidDiskBlockReader(new MemoryStream(buffer));
        //         rigidDiskBlock = await rigidDiskBlockReader.Read(false);
        //         stream.Seek(0, SeekOrigin.Begin);
        //     }
        //     catch (Exception e)
        //     {
        //         throw new Exception($"Failed to rigid disk block from stream: {e}");
        //     }
        //     
        //     return rigidDiskBlock;
        // }

        public abstract Task<Result> Execute();
    }
}