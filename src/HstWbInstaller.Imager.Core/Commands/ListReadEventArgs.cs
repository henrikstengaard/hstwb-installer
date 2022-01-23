namespace HstWbInstaller.Imager.Core.Commands
{
    using System;
    using System.Collections.Generic;

    public class ListReadEventArgs : EventArgs
    {
        public IEnumerable<MediaInfo> MediaInfos;

        public ListReadEventArgs(IEnumerable<MediaInfo> mediaInfos)
        {
            this.MediaInfos = mediaInfos;
        }
    }
}