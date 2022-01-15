namespace HstWbInstaller.Imager.ConsoleApp.Commands
{
    using System.Collections.Generic;
    using System.Text.Json;
    using System.Threading.Tasks;
    using Core;

    public abstract class CommandBase
    {
        protected static readonly JsonSerializerOptions JsonSerializerOptions = new()
        {
            WriteIndented = true
        };

        public abstract Task Execute(IEnumerable<IPhysicalDrive> physicalDrives, Arguments arguments);
    }
}