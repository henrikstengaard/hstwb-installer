namespace HstWbInstaller.Imager.Core.Commands
{
    using HstWbInstaller.Core;

    public class PathNotFoundError : Error
    {
        public readonly string Path;
        
        public PathNotFoundError(string message, string path) : base(message)
        {
            Path = path;
        }
    }
}