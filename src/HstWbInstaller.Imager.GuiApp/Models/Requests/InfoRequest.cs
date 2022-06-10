namespace HstWbInstaller.Imager.GuiApp.Models.Requests
{
    using System.ComponentModel.DataAnnotations;

    public class InfoRequest
    {
        public enum SourceTypeEnum
        {
            ImageFile,
            PhysicalDisk
        }
        
        [Required] 
        public SourceTypeEnum SourceType { get; set; }

        [Required] 
        public string Path { get; set; }
    }
}