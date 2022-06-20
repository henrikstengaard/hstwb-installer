namespace HstWbInstaller.Core.IO.Images
{
    using System;
    using System.Collections.Generic;
    using System.Drawing;
    using System.Drawing.Imaging;
    using System.IO;
    using System.Linq;
    using System.Runtime.InteropServices;
    using System.Text;
    using System.Threading.Tasks;
    using Extensions;
    using RigidDiskBlocks;
    
    public static class IffImageWriter
    {
        /// <summary>
        /// Write image to stream
        /// </summary>
        /// <param name="stream"></param>
        /// <param name="image"></param>
        /// <param name="pack"></param>
        public static async Task Write(Stream stream, Image image, bool pack = true)
        {
            var data = await BuildIlbmImage(image as System.Drawing.Bitmap, pack);
            await stream.WriteBytes(data);
        }

        /// <summary>
        /// Build iff chunk with id and data
        /// </summary>
        /// <param name="id"></param>
        /// <param name="data"></param>
        /// <returns></returns>
        public static async Task<byte[]> BuildIffChunk(string id, byte[] data)
        {
            var chunk = new MemoryStream();

            var chunkLength = data.Length;

            var appendZero = false;
            if ((chunkLength & 1) == 1)
            {
                chunkLength++;
                appendZero = true;
            }

            await chunk.WriteBytes(Encoding.ASCII.GetBytes(id));
            await chunk.WriteBytes(LittleEndianConverter.ConvertToBytes(chunkLength));
            await chunk.WriteBytes(data);

            if (appendZero)
            {
                await chunk.WriteBytes(new byte[1]);
            }

            return chunk.ToArray();
        }

        /// <summary>
        /// Build bitmap header chunk containing information defining the metrics of the image data
        /// </summary>
        /// <param name="image"></param>
        /// <param name="depth"></param>
        /// <param name="pack"></param>
        /// <returns></returns>
        public static async Task<byte[]> BuildBitMapHeaderChunk(Image image, int depth, bool pack)
        {
            var chunk = new MemoryStream();

            await chunk.WriteBytes(LittleEndianConverter.ConvertToBytes((ushort)image.Width)); // width
            await chunk.WriteBytes(LittleEndianConverter.ConvertToBytes((ushort)image.Height)); // height 
            await chunk.WriteBytes(LittleEndianConverter.ConvertToBytes((ushort)0)); // x
            await chunk.WriteBytes(LittleEndianConverter.ConvertToBytes((ushort)0)); // y
            chunk.WriteByte((byte)depth); // planes
            chunk.WriteByte(0); // mask
            chunk.WriteByte((byte)(pack ? 1 : 0)); // tcomp
            chunk.WriteByte(0); // pad1
            await chunk.WriteBytes(LittleEndianConverter.ConvertToBytes((ushort)0)); // transparent color
            chunk.WriteByte(60); // xAspect
            chunk.WriteByte(60); // yAspect
            await chunk.WriteBytes(LittleEndianConverter.ConvertToBytes((ushort)image.Width)); // Lpage
            await chunk.WriteBytes(LittleEndianConverter.ConvertToBytes((ushort)image.Height)); // Hpage

            return await BuildIffChunk(ChunkIdentifiers.BitmapHeader, chunk.ToArray());
        }

        /// <summary>
        /// Build color map chunk storing color information for the image data
        /// </summary>
        /// <param name="image"></param>
        /// <param name="depth"></param>
        /// <returns></returns>
        public static async Task<byte[]> BuildColorMapChunk(Image image, int depth)
        {
            var chunk = new MemoryStream();

            foreach (var color in image.Palette.Entries)
            {
                if (depth == 8)
                {
                    chunk.WriteByte(color.R);
                    chunk.WriteByte(color.G);
                    chunk.WriteByte(color.B);
                }
                else
                {
                    chunk.WriteByte((byte)((color.R & 0xf0) | (color.R >> depth)));
                    chunk.WriteByte((byte)((color.G & 0xf0) | (color.G >> depth)));
                    chunk.WriteByte((byte)((color.B & 0xf0) | (color.B >> depth)));
                }
            }

            return await BuildIffChunk(ChunkIdentifiers.ColorMap, chunk.ToArray());
        }

        // create camg chunk
        public static async Task<byte[]> CamgChunk(Image image, int depth)
        {
            var chunk = new MemoryStream();

            await chunk.WriteBytes(LittleEndianConverter.ConvertToBytes((uint)depth)); // y

            return await BuildIffChunk(ChunkIdentifiers.Camg, chunk.ToArray());
            /*
            return ,$cmagStream.ToArray()

# if mode is not None:
        # camg = iff_chunk("CAMG", struct.pack(">L", mode))
# else:
# camg = ""
                # //    uint viewmodes = input.ReadBEUInt32();

                # //    bytesloaded = size;
                # //    if ((viewmodes & 0x0800) > 0)
                # //        flagHAM = true;
                # //    if ((viewmodes & 0x0080) > 0)
                # //        flagEHB = true;
                # //}
*/
        }

        public static int FindNextDuplicate(byte[] bytes, int start)
        {
            // int last = -1;
            if (start >= bytes.Length)
            {
                return -1;
            }

            var prev = bytes[start];

            for (var i = start + 1; i < bytes.Length; i++)
            {
                var b = bytes[i];

                if (b == prev)
                {
                    return i - 1;
                }

                prev = b;
            }

            return -1;
        }

        public static int FindRunLength(byte[] bytes, int start)
        {
            var b = bytes[start];

            var i = 0;

            for (i = start + 1; (i < bytes.Length) && (bytes[i] == b); i++)
            {
                // do nothing
            }

            return i - start;
        }

        public static byte[] Compress(byte[] bytes)
        {
            var baos = new MemoryStream();
            // max length 1 extra byte for every 128
            var ptr = 0;
            while (ptr < bytes.Length)
            {
                var dup = FindNextDuplicate(bytes, ptr);

                if (dup == ptr)
                {
                    // write run length
                    var len = FindRunLength(bytes, dup);
                    var actualLen = Math.Min(len, 128);
                    baos.WriteByte((byte)(256 - (actualLen - 1)));
                    baos.WriteByte(bytes[ptr]);
                    ptr += actualLen;
                }
                else
                {
                    // write literals
                    var len = dup - ptr;

                    if (dup < 0)
                    {
                        len = bytes.Length - ptr;
                    }

                    var actualLen = Math.Min(len, 128);
                    baos.WriteByte((byte)(actualLen - 1));
                    for (var i = 0; i < actualLen; i++)
                    {
                        baos.WriteByte(bytes[ptr]);
                        ptr++;
                    }
                }
            }

            return baos.ToArray();
        }

        public static int GetPaletteIndex(byte[] imageBytes, int stride, int height, int depth, int x, int y)
        {
            var offset = y;
            if (stride < 0)
            {
                offset = y - height + 1;
            }

            var biti = (offset * stride * 8) + (x * depth);

            // get the byte index
            var i = Convert.ToInt32(Math.Floor((double)biti / 8));

            var c = 0;
            if (depth == 8)
            {
                c = imageBytes[i];
            }

            if (depth == 4)
            {
                if (biti % 8 == 0)
                {
                    c = imageBytes[i] >> 4;
                }
                else
                {
                    c = imageBytes[i] & 0x0F;
                }
            }

            if (depth == 1)
            {
                var bbi = biti % 8;
                var mask = bbi << 1;
                c = (imageBytes[i] & mask) == 0 ? 1 : 0;
            }

            return c;
        }

        public static int CalculateBpr(int width)
        {
            var planeWidth = Math.Floor(((double)width + 15) / 16) * 16;
            return Convert.ToInt32(Math.Floor(planeWidth / 8));
        }

        /// <summary>
        /// Convert image to planes
        /// </summary>
        /// <param name="image"></param>
        /// <param name="depth"></param>
        /// <param name="bpr"></param>
        /// <returns></returns>
        public static IEnumerable<byte[]> ConvertPlanar(System.Drawing.Bitmap image, int depth, int bpr)
        {
            var rect = Rectangle.FromLTRB(0, 0, image.Width, image.Height);
            var imageData = image.LockBits(rect, ImageLockMode.ReadOnly, image.PixelFormat);
            var dataPointer = imageData.Scan0;

            var totalBytes = imageData.Stride * image.Height;
            var imageBytes = new byte[totalBytes];
            Marshal.Copy(dataPointer, imageBytes, 0, totalBytes);
            image.UnlockBits(imageData);

            // Calculate dimensions.
            var planeSize = Convert.ToInt32(bpr * image.Height);

            var planes = new List<byte[]>();

            for (var plane = 0; plane < depth; plane++)
            {
                planes.Add(new byte[planeSize]);
            }

            for (var y = 0; y < image.Height; y++)
            {
                var rowOffset = y * bpr;
                for (var x = 0; x < image.Width; x++)
                {
                    var offset = Convert.ToInt32(rowOffset + Math.Floor((double)x / 8));
                    var xmod = 7 - (x & 7);

                    var paletteIndex = GetPaletteIndex(imageBytes, imageData.Stride, image.Height, depth, x, y);

                    for (var plane = 0; plane < depth; plane++)
                    {
                        planes[plane][offset] = (byte)(planes[plane][offset] | (((paletteIndex >> plane) & 1) << xmod));
                    }
                }
            }

            return planes;
        }

        /// <summary>
        /// Build body chunk storing the actual image data as a byte array
        /// </summary>
        /// <param name="image"></param>
        /// <param name="depth"></param>
        /// <param name="pack"></param>
        /// <returns></returns>
        public static async Task<byte[]> BuildBodyChunk(System.Drawing.Bitmap image, int depth, bool pack)
        {
            // Get planar bitmap.
            var bpr = CalculateBpr(image.Width);
            var planes = ConvertPlanar(image, depth, bpr).ToList();

            var chunk = new MemoryStream();

            for (var y = 0; y < image.Height; y++)
            {
                for (var plane = 0; plane < depth; plane++)
                {
                    var row = new byte[bpr];
                    Array.Copy(planes[plane], y * bpr, row, 0, bpr);

                    if (pack)
                    {
                        row = Compress(row);
                    }

                    await chunk.WriteBytes(row);
                }
            }

            return await BuildIffChunk(ChunkIdentifiers.Body, chunk.ToArray());
        }

        // cfreate ilbm image
        public static async Task<byte[]> BuildIlbmImage(System.Drawing.Bitmap image, bool pack)
        {
            if (!(image.PixelFormat == PixelFormat.Format4bppIndexed ||
                  image.PixelFormat == PixelFormat.Format8bppIndexed))
            {
                throw new ArgumentException(
                    $"Image with pixel format '{image.PixelFormat}' is not supported. Only 4-bpp or 8-bpp indexed image is supported!");
            }

            var depth = Image.GetPixelFormatSize(image.PixelFormat);

            var chunk = new MemoryStream();

            await chunk.WriteBytes(Encoding.ASCII.GetBytes(ChunkIdentifiers.InterLeavedBitmap));
            await chunk.WriteBytes(await BuildBitMapHeaderChunk(image, depth, pack));
            await chunk.WriteBytes(await BuildColorMapChunk(image, depth));
            await chunk.WriteBytes(await BuildBodyChunk(image, depth, pack));

            return await BuildIffChunk(ChunkIdentifiers.Form, chunk.ToArray());
        }
    }
}