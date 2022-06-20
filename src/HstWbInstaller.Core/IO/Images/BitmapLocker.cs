namespace HstWbInstaller.Core.IO.Images
{
    using System;
    using System.Drawing;
    using System.Drawing.Imaging;
    using System.Runtime.InteropServices;

    /// <summary>
    /// https://stackoverflow.com/questions/51071944/how-can-i-work-with-1-bit-and-4-bit-images
    /// https://stackoverflow.com/questions/2593212/editing-8bpp-indexed-bitmaps
    /// </summary>
    public class BitmapLocker : IDisposable
    {
        //private properties
        System.Drawing.Bitmap bitmap = null;
        BitmapData bitmapData = null;
        private byte[] imageData = null;

        //public properties
        public bool IsLocked { get; set; }
        public IntPtr IntegerPointer { get; private set; }

        public int Width
        {
            get
            {
                if (IsLocked == false) throw new InvalidOperationException("not locked");
                return bitmapData.Width;
            }
        }

        public int Height
        {
            get
            {
                if (IsLocked == false) throw new InvalidOperationException("not locked");
                return bitmapData.Height;
            }
        }

        public int Stride
        {
            get
            {
                if (IsLocked == false) throw new InvalidOperationException("not locked");
                return bitmapData.Stride;
            }
        }

        public int ColorDepth
        {
            get
            {
                if (IsLocked == false) throw new InvalidOperationException("not locked");
                return Image.GetPixelFormatSize(bitmapData.PixelFormat);
            }
        }

        public int Channels
        {
            get
            {
                if (IsLocked == false) throw new InvalidOperationException("not locked");
                return ColorDepth / 8;
            }
        }

        public int PaddingOffset
        {
            get
            {
                if (IsLocked == false) throw new InvalidOperationException("not locked");
                return bitmapData.Stride - (bitmapData.Width * Channels);
            }
        }

        public PixelFormat ImagePixelFormat
        {
            get
            {
                if (IsLocked == false) throw new InvalidOperationException("not locked");
                return bitmapData.PixelFormat;
            }
        }

        public ColorPalette Palette
        {
            get
            {
                if (IsLocked == false) throw new InvalidOperationException("not locked");
                return bitmap.Palette;
            }
        }

        //Constructor
        public BitmapLocker(System.Drawing.Bitmap source)
        {
            IsLocked = false;
            IntegerPointer = IntPtr.Zero;
            this.bitmap = source;
        }

        /// Lock bitmap
        public void Lock()
        {
            if (IsLocked == false)
            {
                // Lock bitmap (so that no movement of data by .NET framework) and return bitmap data
                bitmapData = bitmap.LockBits(
                    new Rectangle(0, 0, bitmap.Width, bitmap.Height),
                    ImageLockMode.ReadWrite,
                    bitmap.PixelFormat);

                // Create byte array to copy pixel values
                int noOfBytesNeededForStorage = Math.Abs(bitmapData.Stride) * bitmapData.Height;
                imageData = new byte[noOfBytesNeededForStorage];

                IntegerPointer = bitmapData.Scan0;

                // Copy data from IntegerPointer to _imageData
                Marshal.Copy(IntegerPointer, imageData, 0, imageData.Length);

                IsLocked = true;
            }
            else
            {
                throw new Exception("Bitmap is already locked.");
            }
        }

        /// Unlock bitmap
        public void Unlock()
        {
            if (IsLocked)
            {
                // Copy data from _imageData to IntegerPointer
                Marshal.Copy(imageData, 0, IntegerPointer, imageData.Length);

                // Unlock bitmap data
                bitmap.UnlockBits(bitmapData);

                IsLocked = false;
            }
            else
            {
                throw new Exception("Bitmap is not locked.");
            }
        }

        public int GetPaletteEntry(int x, int y)
        {
            if (ColorDepth > 8)
            {
                throw new Exception();
            }

            // Get the bit index of the specified pixel
            var bitIndex = (Stride > 0 ? y : y - Height + 1) * Stride * 8 + x * ColorDepth;
            // Get the byte index
            var i = bitIndex / 8;

            // Get color components count
            var cCount = ColorDepth / 8;
            var dataLength = imageData.Length - cCount;

            if (i > dataLength)
            {
                throw new IndexOutOfRangeException();
            }
            
            if (ColorDepth == 8)
            {
                var c = imageData[i];
                if (Palette.Entries.Length <= c)
                    throw new InvalidOperationException("no palette");
                return c;
            }

            if (ColorDepth == 4)
            {
                var c = bitIndex % 8 == 0 ? (byte)(imageData[i] >> 4) : (byte)(imageData[i] & 0xF);
                if (Palette.Entries.Length <= c)
                    throw new InvalidOperationException("no palette");
                return c;
            }

            if (ColorDepth == 1)
            {
                var bbi = bitIndex % 8;
                var mask = (byte)(1 << bbi);
                var c = (byte)((imageData[i] & mask) != 0 ? 1 : 0);
                if (Palette.Entries.Length <= c)
                    throw new InvalidOperationException("no palette");
                return c;
            }

            return -1;
        }

        public Color GetPixel(int x, int y)
        {
            // Get the bit index of the specified pixel
            var bitIndex = (Stride > 0 ? y : y - Height + 1) * Stride * 8 + x * ColorDepth;
            // Get the byte index
            var i = bitIndex / 8;

            // Get color components count
            var cCount = ColorDepth / 8;
            var dataLength = imageData.Length - cCount;

            if (i > dataLength)
            {
                throw new IndexOutOfRangeException();
            }

            if (ColorDepth == 32) // For 32 bpp get Red, Green, Blue and Alpha
            {
                var b = imageData[i];
                var g = imageData[i + 1];
                var r = imageData[i + 2];
                var a = imageData[i + 3]; // a
                return Color.FromArgb(a, r, g, b);
            }

            if (ColorDepth == 24) // For 24 bpp get Red, Green and Blue
            {
                var b = imageData[i];
                var g = imageData[i + 1];
                var r = imageData[i + 2];
                return Color.FromArgb(r, g, b);
            }

            var paletteEntry = GetPaletteEntry(x, y);
            return Palette.Entries[paletteEntry];
        }

        public void SetPixel(int x, int y, int paletteIndex)
        {
            if (!IsLocked) throw new Exception();

            // Get the bit index of the specified pixel
            var bitIndex = (Stride > 0 ? y : y - Height + 1) * Stride * 8 + x * ColorDepth;
            // Get the byte index
            var i = bitIndex / 8;

            if (ColorDepth == 8)
            {
                imageData[i] = (byte)paletteIndex;
                return;
            }

            if (ColorDepth == 4)
            {
                if (bitIndex % 8 == 0)
                {
                    imageData[i] = (byte)((imageData[i] & 0xF) | (paletteIndex << 4));
                }
                else
                {
                    imageData[i] = (byte)((imageData[i] & 0xF0) | paletteIndex);
                }
                return;
            }

            if (ColorDepth == 1)
            {
                int bbi = bitIndex % 8;
                byte mask = (byte)(1 << bbi);
                if (paletteIndex != 0)
                {
                    imageData[i] |= mask;
                }
                else
                {
                    imageData[i] &= (byte)~mask;
                }
            }
        }

        public void SetPixel(int x, int y, Color color)
        {
            if (!IsLocked) throw new Exception();

            // Get the bit index of the specified pixel
            var bitIndex = (Stride > 0 ? y : y - Height + 1) * Stride * 8 + x * ColorDepth;
            // Get the byte index
            var i = bitIndex / 8;

            if (ColorDepth == 32) // For 32 bpp set Red, Green, Blue and Alpha
            {
                imageData[i] = color.B;
                imageData[i + 1] = color.G;
                imageData[i + 2] = color.R;
                imageData[i + 3] = color.A;
                return;
            }

            if (ColorDepth == 24) // For 24 bpp set Red, Green and Blue
            {
                imageData[i] = color.B;
                imageData[i + 1] = color.G;
                imageData[i + 2] = color.R;
                return;
            }
            
            var paletteIndex = 0;
            for (var j = 0; j < Palette.Entries.Length; j++)
            {
                if (Palette.Entries[j].R != color.R || Palette.Entries[j].G != color.G ||
                    Palette.Entries[j].B != color.B)
                {
                    continue;
                }
                paletteIndex = (byte)j;
                break;
            }
            
            SetPixel(x, y, paletteIndex);
        }

        public void Dispose()
        {
            Dispose(true);
            GC.SuppressFinalize(this);
        }

        protected virtual void Dispose(bool disposing)
        {
            if (!disposing)
            {
                return;
            }
            // free managed resources
            bitmap = null;
            bitmapData = null;
            imageData = null;
            IntegerPointer = IntPtr.Zero;
        }
    }
}