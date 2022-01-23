namespace HstWbInstaller.Imager.Core.Commands
{
    using System;

    public class InfoReadEventArgs : EventArgs
    {
        public MediaInfo MediaInfo;

        public InfoReadEventArgs(MediaInfo mediaInfo)
        {
            this.MediaInfo = mediaInfo;
        }
    }
}