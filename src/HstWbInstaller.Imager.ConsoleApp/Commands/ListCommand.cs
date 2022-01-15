namespace HstWbInstaller.Imager.ConsoleApp.Commands
{
    using System;
    using System.Collections.Generic;
    using System.Text.Json;
    using System.Threading.Tasks;
    using Core;

    public class ListCommand : CommandBase
    {
        public override async Task Execute(IEnumerable<IPhysicalDrive> physicalDrives, Arguments arguments)
        {
            await Task.Run(() =>
            {
                Console.WriteLine(JsonSerializer.Serialize(physicalDrives, JsonSerializerOptions));
            });
        }
    }
}