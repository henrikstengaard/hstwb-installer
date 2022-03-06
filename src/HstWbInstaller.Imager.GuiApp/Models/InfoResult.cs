namespace HstWbInstaller.Imager.GuiApp.Models
{
    using System.Collections.Generic;
    using Core.Commands;

    public class InfoResult
    {
        public IEnumerable<MediaInfo> MediaInfos { get; set; }
    }
}