# https://github.com/hubkey/Trinet.Core.IO.Ntfs/blob/master/src/Trinet.Core.IO.Ntfs/SafeNativeMethods.cs

Add-Type -TypeDefinition @"
using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.IO;
using System.Linq;
using System.Runtime.InteropServices;
using System.Text;
using Microsoft.Win32.SafeHandles;

namespace Win32
{
    public static class SafeNativeMethods
    {
        #region Constants and flags

		[Flags]
		public enum NativeFileFlags : uint
		{
			WriteThrough		= 0x80000000,
			Overlapped			= 0x40000000,
			NoBuffering			= 0x20000000,
			RandomAccess		= 0x10000000,
			SequentialScan		= 0x8000000,
			DeleteOnClose		= 0x4000000,
			BackupSemantics		= 0x2000000,
			PosixSemantics		= 0x1000000,
			OpenReparsePoint	= 0x200000,
			OpenNoRecall		= 0x100000
		}

		[Flags]
		public enum NativeFileAccess : uint
		{
			GenericRead		= 0x80000000,
			GenericWrite	= 0x40000000
		}

		#endregion

		#region P/Invoke Structures

		[StructLayout(LayoutKind.Sequential)]
		private struct LargeInteger
		{
			public readonly int Low;
			public readonly int High;

			public long ToInt64()
			{
				return (this.High * 0x100000000) + this.Low;
			}

			/*
			public static LargeInteger FromInt64(long value)
			{
				return new LargeInteger
				{
					Low = (int)(value & 0x11111111),
					High = (int)((value / 0x100000000) & 0x11111111)
				};
			}
			*/
        }

        #endregion

        #region P/Invoke Methods
        
		[DllImport("kernel32.dll", CharSet = CharSet.Auto, BestFitMapping = false, ThrowOnUnmappableChar = true)]
		private static extern int FormatMessage(
			int dwFlags, 
			IntPtr lpSource, 
			int dwMessageId, 
			int dwLanguageId, 
			StringBuilder lpBuffer, 
			int nSize, 
			IntPtr vaListArguments);
              
		[DllImport("kernel32", CharSet = CharSet.Unicode, SetLastError = true)]
		[return: MarshalAs(UnmanagedType.Bool)]
        private static extern bool GetFileSizeEx(SafeFileHandle handle, out LargeInteger size);
        
		[DllImport("kernel32.dll")]
		private static extern int GetFileType(SafeFileHandle handle);

        [DllImport("kernel32", CharSet = CharSet.Unicode, SetLastError = true)]
		private static extern SafeFileHandle CreateFile(
			string name,
			NativeFileAccess access,
			FileShare share,
			IntPtr security,
			FileMode mode,
			NativeFileFlags flags,
            IntPtr template);

        #endregion

        #region Utility Methods
    
		private static int MakeHRFromErrorCode(int errorCode)
		{
			return (-2147024896 | errorCode);
        }

		private static string GetErrorMessage(int errorCode)
		{
			var lpBuffer = new StringBuilder(0x200);
			if (0 != FormatMessage(0x3200, IntPtr.Zero, errorCode, 0, lpBuffer, lpBuffer.Capacity, IntPtr.Zero))
			{
				return lpBuffer.ToString();
			}

			return string.Format("Error_UnknownError: {0}", errorCode);
        }
                
        public static SafeFileHandle SafeCreateFile(string path, NativeFileAccess access, FileShare share, IntPtr security, FileMode mode, NativeFileFlags flags, IntPtr template)
        {
            SafeFileHandle result = CreateFile(path, access, share, security, mode, flags, template);
            if (!result.IsInvalid && 1 != GetFileType(result))
            {
                result.Dispose();
                throw new NotSupportedException(string.Format(
                    "Error_NonFile: {0}", path));
            }

            return result;
        }

		private static void ThrowIOError(int errorCode, string path)
		{
			switch (errorCode)
			{
				case 0:
				{
					break;
				}
				case 2: // File not found
				{
					if (string.IsNullOrEmpty(path)) throw new FileNotFoundException();
					throw new FileNotFoundException(null, path);
				}
				case 3: // Directory not found
				{
					if (string.IsNullOrEmpty(path)) throw new DirectoryNotFoundException();
					throw new DirectoryNotFoundException(string.Format("Error_DirectoryNotFound: {0}", path));
				}
				case 5: // Access denied
				{
					if (string.IsNullOrEmpty(path)) throw new UnauthorizedAccessException();
					throw new UnauthorizedAccessException(string.Format("Error_AccessDenied_Path: {0}", path));
				}
				case 15: // Drive not found
				{
					if (string.IsNullOrEmpty(path)) throw new DriveNotFoundException();
					throw new DriveNotFoundException(string.Format("Error_DriveNotFound: {0}", path));
				}
				case 32: // Sharing violation
				{
					if (string.IsNullOrEmpty(path)) throw new IOException(GetErrorMessage(errorCode), MakeHRFromErrorCode(errorCode));
					throw new IOException(string.Format("Error_SharingViolation: {0}", path), MakeHRFromErrorCode(errorCode));
				}
				case 80: // File already exists
				{
					if (!string.IsNullOrEmpty(path))
					{
						throw new IOException(string.Format("FileAlreadyExists: {0}", path), MakeHRFromErrorCode(errorCode));
					}
					break;
				}
				case 87: // Invalid parameter
				{
					throw new IOException(GetErrorMessage(errorCode), MakeHRFromErrorCode(errorCode));
				}
				case 183: // File or directory already exists
				{
					if (!string.IsNullOrEmpty(path))
					{
						throw new IOException(string.Format("Error_AlreadyExists: {0}", path), MakeHRFromErrorCode(errorCode));
					}
					break;
				}
				case 206: // Path too long
				{
					throw new PathTooLongException();
				}
				case 995: // Operation cancelled
				{
					throw new OperationCanceledException();
				}
				default:
				{
					Marshal.ThrowExceptionForHR(MakeHRFromErrorCode(errorCode));
					break;
				}
			}
        }
                
		public static void ThrowLastIOError(string path)
		{
			int errorCode = Marshal.GetLastWin32Error();
			if (0 != errorCode)
			{
				int hr = Marshal.GetHRForLastWin32Error();
				if (0 <= hr) throw new Win32Exception(errorCode);
				ThrowIOError(errorCode, path);
			}
        }

		public static NativeFileAccess ToNative(this FileAccess access)
		{
			NativeFileAccess result = 0;
			if (FileAccess.Read == (FileAccess.Read & access)) result |= NativeFileAccess.GenericRead;
			if (FileAccess.Write == (FileAccess.Write & access)) result |= NativeFileAccess.GenericWrite;
			return result;
        }
                
        private static long GetFileSize(string path, SafeFileHandle handle)
        {
            long result = 0L;
            if (null != handle && !handle.IsInvalid)
            {

                LargeInteger value;
                if (GetFileSizeEx(handle, out value))
                {
                    result = value.ToInt64();
                }
                else
                {
                    ThrowLastIOError(path);
                }
            }

            return result;
        }

        public static long GetFileSize(string path)
        {
            long result = 0L;
            if (!string.IsNullOrEmpty(path))
            {
                using (SafeFileHandle handle = SafeCreateFile(path, NativeFileAccess.GenericRead, FileShare.Read, IntPtr.Zero, FileMode.Open, 0, IntPtr.Zero))
                {
                    result = GetFileSize(path, handle);
                }
            }

            return result;
        }

        

        #endregion
    }
}
"@

#$path = "\\.\{0}" -f "f:"
$path = "C:\temp\hdf_repack\image.json"

[Win32.SafeNativeMethods]::GetFileSize($path)