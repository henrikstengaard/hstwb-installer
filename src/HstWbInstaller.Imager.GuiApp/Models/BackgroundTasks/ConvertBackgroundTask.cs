﻿namespace HstWbInstaller.Imager.GuiApp.Models.BackgroundTasks
{
    using System.Threading;
    using Services;

    public class ConvertBackgroundTask : IBackgroundTask
    {
        public CancellationToken Token { get; set; }
        public string Title { get; set; }
        public string SourcePath { get; set; }
        public string DestinationPath { get; set; }
    }
}