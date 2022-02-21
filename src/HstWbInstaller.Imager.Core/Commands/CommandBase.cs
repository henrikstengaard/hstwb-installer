namespace HstWbInstaller.Imager.Core.Commands
{
    using System;
    using System.Collections.Generic;
    using System.Linq;
    using System.Text.Json;
    using System.Threading;
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

        public abstract Task<Result> Execute(CancellationToken token);
    }
}