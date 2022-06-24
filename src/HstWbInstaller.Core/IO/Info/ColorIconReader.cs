namespace HstWbInstaller.Core.IO.Info
{
    using System;
    using System.Collections.Generic;
    using System.IO;
    using System.Linq;
    using System.Threading.Tasks;
    using Extensions;
    using Images.Bitmap;

    public static class ColorIconReader
    {
        public static async Task<ColorIcon> Read(Stream stream)
        {
            var diskObject = await DiskObjectReader.Read(stream);

            var formChunkIdentifier = BitConverter.ToUInt32(await stream.ReadBytes(4));
            if (formChunkIdentifier != ColorIconChunkIdentifiers.FORM)
            {
                throw new IOException("Invalid form chunk identifier");
            }

            var formChunkSize = await stream.ReadUInt32();

            var iconChunkIdentifier = BitConverter.ToUInt32(await stream.ReadBytes(4));
            if (iconChunkIdentifier != ColorIconChunkIdentifiers.ICON)
            {
                throw new IOException("Invalid icon chunk identifier");
            }

            FaceChunk faceChunk = null;
            var colorIconImages = new List<ColorIconImage>();

            while (stream.Position < stream.Length)
            {
                var chunkIdentifier = BitConverter.ToUInt32(await stream.ReadBytes(4));
                var chunkSize = await stream.ReadUInt32();

                switch (chunkIdentifier)
                {
                    case ColorIconChunkIdentifiers.FACE:
                        faceChunk = await ReadFace(stream);
                        break;
                    case ColorIconChunkIdentifiers.IMAG:
                        if (faceChunk == null)
                        {
                            throw new IOException("FACE chunk not found");
                        }

                        colorIconImages.Add(await ReadImag(stream, faceChunk));
                        break;
                    default:
                        // unknown chunk, skip
                        stream.Seek(chunkSize, SeekOrigin.Current);
                        break;
                }
            }

            if (faceChunk == null)
            {
                throw new IOException("FACE chunk not found");
            }
            
            return new ColorIcon
            {
                Width = faceChunk.Width,
                Height = faceChunk.Height,
                Images = colorIconImages.ToArray()
            };
        }
        
        private static async Task<FaceChunk> ReadFace(Stream stream)
        {
            var width = stream.ReadByte();
            var height = stream.ReadByte();
            var flags = stream.ReadByte();
            var aspect = stream.ReadByte();
            var maxPalBytes = await stream.ReadUInt16();

            return new FaceChunk
            {
                Width = width + 1,
                Height = height + 1,
                Flags = flags,
                Aspect = aspect,
                MaxPalBytes = maxPalBytes
            };
        }

        private static async Task<ColorIconImage> ReadImag(Stream stream, FaceChunk faceChunk)
        {
            var transparentColor = stream.ReadByte();
            var numColors = stream.ReadByte() + 1;
            var flags = stream.ReadByte();

            var imageCompressed = stream.ReadByte() == 1; // 0 = uncompressed, 1 = compressed
            var paletteCompressed = stream.ReadByte() == 1; // 0 = uncompressed, 1 = compressed
            var depth = stream.ReadByte();

            var imageSize = (await stream.ReadUInt16()) + 1;
            var paletteSize = (await stream.ReadUInt16()) + 1;

            // pad uneven to even
            if (imageSize + paletteSize % 2 != 0)
            {
                paletteSize++;
            }

            // var imageData = await stream.ReadBytes(imageSize);
            // var d = glowdata_uncompress(imageData, 0, imageSize, depth);
            // await File.WriteAllBytesAsync("d.bin", d);
            // var paletteData = await stream.ReadBytes(paletteSize);

            var pixels =
                (imageCompressed
                    ? ReadCompressedPixels(stream, faceChunk.Width, faceChunk.Height, depth, imageSize)
                    : ReadUncompressedPixels(stream, faceChunk.Width, faceChunk.Height, imageSize)).ToArray();

            // if palette is attached
            var palette = Array.Empty<Color>();
            if ((flags & 1) == 1)
            {
                palette = (paletteCompressed
                    ? ReadCompressedPalette(stream, numColors, paletteSize, transparentColor)
                    : ReadUncompressedPalette(stream, numColors, paletteSize, transparentColor)).ToArray();
            }

            // var pixelOffset = 0;
            //
            //
            // var imageStream = new MemoryStream(imageData);
            // var reader = new RleStreamReader(imageStream, depth);
            // for (var y = 0; y < faceChunk.Height; y++)
            // {
            //     for (var x = 0; x < faceChunk.Width; x++)
            //     {
            //         pixels[pixelOffset++] = reader.ReadData8();
            //     }
            // }

            //var t = await File.ReadAllBytesAsync("d.bin");
            
            
            return new ColorIconImage
            {
                Width = faceChunk.Width,
                Height = faceChunk.Height,
                Palette = palette,
                Pixels = pixels
            };
        }

        private static IEnumerable<Color> ReadUncompressedPalette(Stream stream, int numColors, int paletteSize, int transparentColor)
        {
            var position = stream.Position;
            for (var i = 0; i < numColors; i++)
            {
                var r = stream.ReadByte();
                var g = stream.ReadByte();
                var b = stream.ReadByte();
                yield return new Color
                {
                    R = r,
                    G = g,
                    B = b,
                    A = transparentColor == i ? 0 : 255
                };
            }

            stream.Seek(position + paletteSize, SeekOrigin.Begin);
        }

        private static IEnumerable<Color> ReadCompressedPalette(Stream stream, int numColors, int paletteSize, int transparentColor)
        {
            var position = stream.Position;
            var reader = new RleStreamReader(stream, 8, paletteSize);
            for (var i = 0; i < numColors; i++)
            {
                var r = reader.ReadData8();
                var g = reader.ReadData8();
                var b = reader.ReadData8();
                yield return new Color
                {
                    R = r,
                    G = g,
                    B = b,
                    A = transparentColor == i ? 0 : 255
                };
            }

            stream.Seek(position + paletteSize, SeekOrigin.Begin);
        }

        private static IEnumerable<byte> ReadCompressedPixels(Stream stream, int width, int height, int depth,
            int imageSize)
        {
            var position = stream.Position;
            var pixels = new byte[width * height];

            var reader = new RleStreamReader(stream, depth, imageSize);

            for (var i = 0; i < pixels.Length; i++)
            {
                pixels[i] = reader.ReadData8();
            }

            stream.Seek(position + imageSize, SeekOrigin.Begin);

            return pixels;
        }

        private static IEnumerable<byte> ReadUncompressedPixels(Stream stream, int width, int height, int imageSize)
        {
            var position = stream.Position;
            var pixels = new byte[width * height];

            for (var i = 0; i < pixels.Length; i++)
            {
                pixels[i] = (byte)stream.ReadByte();
            }

            stream.Seek(position + imageSize, SeekOrigin.Begin);

            return pixels;
        }
        
// Uncompress a slice of f, and append to outf.
// The algorithm is the same as PackBits, except that the data elements may
// be less than 8 bits.
        private static byte[] glowdata_uncompress(byte[] f, int pos, int len, int bits_per_pixel)
        {
            var outf = new List<byte>();
            
            int x;
            int i;
            byte b, b2;
            int bitpos;

            bitpos = 0;

            // Continue as long as at least 8 bits remain.
            while(bitpos <= (len-1)*8) {
                b = de_get_bits_symbol2(f, 8, pos, bitpos);
                bitpos+=8;

                if(b<=127) {
                    // 1+b literal pixels
                    x = 1+b;
                    for(i=0; i<x; i++) {
                        b2 = de_get_bits_symbol2(f, bits_per_pixel, pos, bitpos);
                        bitpos += bits_per_pixel;
                        outf.Add(b2);
                    }
                }
                else if(b>=129) {
                    // 257-b repeated pixels
                    x = 257 - b;
                    b2 = de_get_bits_symbol2(f, bits_per_pixel, pos, bitpos);
                    bitpos += bits_per_pixel;
                    for(i=0; i<x; i++) {
                        outf.Add(b2);
                    }
                }
            }

            return outf.ToArray();
        }
        
// Read a symbol (up to 8 bits) that starts at an arbitrary bit position.
// It may span (two) bytes.
        private static byte de_get_bits_symbol2(byte[] f, int nbits, int bytepos, int bitpos)
        {
            byte b0, b1;
            int bits_in_first_byte;
            int bits_in_second_byte;

            bits_in_first_byte = 8 - (bitpos % 8);

            b0 = f[bytepos + bitpos / 8];

        if(bits_in_first_byte<8) {
                b0 &= (byte)(0xff >> (8-bits_in_first_byte)); // Zero out insignificant bits
            }

            if(bits_in_first_byte == nbits) {
                // First byte has all the bits
                return b0;
            }
            else if(bits_in_first_byte >= nbits) {
                // First byte has all the bits
                return (byte)(b0 >> (bits_in_first_byte - nbits));
            }

            bits_in_second_byte = nbits - bits_in_first_byte;
            b1 = f[bytepos + bitpos/8 +1];

            return (byte)((b0<<bits_in_second_byte) | (b1>>(8-bits_in_second_byte)));
        }
        
        private static byte de_get_bits_symbol(byte[] f, int bps, int rowstart, int index)
        {
            int byte_offset;
            byte b;
            byte x = 0;

            switch(bps) {
                case 1:
                    byte_offset = rowstart + index/8;
                    b = f[byte_offset];
                    x = (byte)((b >> (7 - index%8)) & 0x01);
                    break;
                case 2:
                    byte_offset = rowstart + index/4;
                    b = f[byte_offset];
                    x = (byte)((b >> (2 * (3 - index%4))) & 0x03);
                    break;
                case 4:
                    byte_offset = rowstart + index/2;
                    b = f[byte_offset];
                    x = (byte)((b >> (4 * (1 - index%2))) & 0x0f);
                    break;
                case 8:
                    byte_offset = rowstart + index;
                    x = f[byte_offset];
                    break;
            }
            return x;
        }        
    }
}