namespace HstWbInstaller.Imager.Core.Helpers
{
    using System;

    public static class TimeHelper
    {
        public static TimeSpan CalculateTimeRemaining(double percentComplete, TimeSpan timeElapsed)
        {
            return percentComplete > 0
                ? TimeSpan.FromMilliseconds((double)timeElapsed.TotalMilliseconds / percentComplete *
                                            (100 - percentComplete))
                : TimeSpan.Zero;
        }
    }
}