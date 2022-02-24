namespace HstWbInstaller.Imager.Core.Apis
{
    using System.Runtime.InteropServices;
    using System.Text;

    public static class Kernel32
    {
        [DllImport("kernel32.dll")]
        public static extern uint QueryDosDevice(string lpDeviceName, StringBuilder lpTargetPath, int ucchMax);
        
        [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
        public static extern uint QueryDosDeviceW(string lpDeviceName, [Out] char[] lpTargetPath, uint ucchMax);
    }
}