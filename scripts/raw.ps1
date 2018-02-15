# https://social.technet.microsoft.com/Forums/windowsserver/en-US/43ce7195-c76c-40eb-b886-63e45336229a/readfile-using-winapi-with-pinvoke-image-a-physical-disk?forum=winserverpowershell
# https://social.msdn.microsoft.com/Forums/vstudio/en-US/db008715-a7a4-4959-9763-e076cd17a665/createfile-setfilepointerex-readfile-don?forum=csharpgeneral
# https://stackoverflow.com/questions/16926127/powershell-to-resolve-junction-target-path
# https://social.msdn.microsoft.com/Forums/vstudio/en-US/db008715-a7a4-4959-9763-e076cd17a665/createfile-setfilepointerex-readfile-don?forum=csharpgeneral


$win32 = add-type -name win32 -passThru -memberDefinition @'        
[DllImport("kernel32.dll", CharSet = CharSet.Auto, CallingConvention = CallingConvention.StdCall, SetLastError = true)]
  public static extern SafeFileHandle CreateFile(
        string lpFileName,
        uint dwDesiredAccess,
        uint dwShareMode,
        IntPtr SecurityAttributes,
        uint dwCreationDisposition,
        uint dwFlagsAndAttributes,
        IntPtr hTemplateFile);

[DllImport("kernel32.dll", CharSet = CharSet.Auto, SetLastError=true)]
public static extern bool CloseHandle(SafeFileHandle handle);

[DllImport("Kernel32.dll", SetLastError = true)]
public static extern uint GetLastError();

[DllImport("kernel32.dll", CharSet = CharSet.Auto, SetLastError=true)]
public static extern uint GetFileSize(SafeFileHandle handle, IntPtr lpFileSizeHigh);

[DllImport("kernel32.dll", CharSet = CharSet.Auto, SetLastError=true)]
public static extern uint GetFileSizeEx(SafeFileHandle handle, out long lpFileSize);

[DllImport("kernel32.dll")]
public static extern bool SetFilePointerEx(SafeFileHandle handle, long liDistanceToMove, IntPtr lpNewFilePointer, uint dwMoveMethod);

[DllImport("kernel32.dll", SetLastError = true)]
public static extern bool ReadFile(SafeFileHandle handle, [Out] byte[] lpBuffer, uint nNumberOfBytesToRead, ref int lpNumberOfBytesRead, IntPtr lpOverlapped);
'@ -UsingNamespace System.Text,Microsoft.Win32.SafeHandles,System.ComponentModel



#DesiredAccess desiredAccess = DesiredAccess.GenericRead;


function Read
{

}



#// For a DISK:
#IntPtr hDisk = CreateFile(string.Format("\\\\.\\PhysicalDrive{0}", diskNumber),

#// For a DRIVE
#IntPtr hDrive = NativeMethods.CreateFile(string.Format("\\\\.\\{0}:", DriveLetter)

# public const DWORD
# GENERIC_READ = 0x80000000,
# GENERIC_WRITE = 0x40000000,
# FILE_SHARE_WRITE = 0x2,
# FILE_SHARE_READ = 0x1,
# OPEN_EXISTING = 0x3;

$path = "\\.\{0}" -f "f:"
$path
$dwDesiredAccess = 2147483648 # GENERIC_READ
$dwShareMode = 0x1 # FILE_SHARE_READ
$lpSecurityAttributes = [IntPtr]::Zero #
$dwCreationDisposition = 3 # OPEN_EXISTING
$dwFlagsAndAttributes = 0x20000000 # FILE_FLAG_NO_BUFFERING
$fileReadAttributes = 0x80 #FILE_READ_ATTRIBUTES = 0x80


$handle = $win32::CreateFile($path, $dwDesiredAccess, $dwShareMode, [IntPtr]::Zero, $dwCreationDisposition, $dwFlagsAndAttributes, [IntPtr]::Zero)
#$handle = $win32::CreateFile($path, $dwDesiredAccess, $dwShareMode, [IntPtr]::Zero, $dwCreationDisposition, $dwFlagsAndAttributes, [IntPtr]::Zero)

if ($handle.IsInvalid)
{
    throw "error opening file"
}

#$currentFilePosition = [uint32]::MinValue
#$win32::SetFilePointerEx($handle, 512, $currentFilePosition, 0)


$buffer = New-Object byte[] 512
$read = [uint32]::MinValue
"read file"
$win32::ReadFile($handle, $buffer, [uint32]512, [ref]$read, [IntPtr]::Zero)
$read
$win32::CloseHandle($handle)

Write-Output $buffer[0]
Write-Output $buffer[1]
Write-Output $buffer[2]
Write-Output $buffer[3]