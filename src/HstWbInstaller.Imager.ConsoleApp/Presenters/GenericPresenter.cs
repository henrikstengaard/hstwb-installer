namespace HstWbInstaller.Imager.ConsoleApp.Presenters
{
    using System;
    using Core;

    public static class GenericPresenter
    {
        public static void Present(DataProcessedEventArgs args)
        {
            Console.WriteLine(
                $"{args.PercentComplete:F1}% ({args.BytesProcessed} / {args.BytesTotal} bytes)");
        }

        public static void PresentPaths(Arguments arguments)
        {
            Console.WriteLine($"Source: {arguments.SourcePath}");
            Console.WriteLine($"Destination: {arguments.DestinationPath}");
        }
    }
}