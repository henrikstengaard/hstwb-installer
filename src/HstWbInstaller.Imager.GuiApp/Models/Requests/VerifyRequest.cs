namespace HstWbInstaller.Imager.GuiApp.Models.Requests
{
    using System.ComponentModel.DataAnnotations;

    public class VerifyRequest
    {
        public enum SourceTypeEnum
        {
            ImageFile,
            PhysicalDisk
        }
        
        [Required]
        public string Title { get; set; }

        [Required] 
        public SourceTypeEnum SourceType { get; set; }
        
        [Required]
        public string SourcePath { get; set; }

        [Required]
        public string DestinationPath { get; set; }
    }
}