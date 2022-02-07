namespace HstWbInstaller.Core.IO.Hunks
{
    using System.Collections.Generic;
    using System.IO;
    using System.Text;
    using System.Threading.Tasks;
    using Extensions;

    public static class HunkReader
    {
        // http://amiga-dev.wikidot.com/file-format:hunk#toc15
        // https://www.markwrobel.dk/post/amiga-machine-code-detour-reverse-engineering/
        // http://amiga.rules.no/abfs/abfs.pdf
        public static async Task<IEnumerable<IHunk>> Parse(Stream stream)
        {
            var header = await ParseHeader(stream);

            var hunks = new List<IHunk>
            {
                header
            };

            IHunk hunk;
            do
            {
                hunk = await ParseHunk(stream);
                hunks.Add(hunk);
            } while (hunk != null && hunk.Identifier != HunkIdentifiers.End);

            return hunks;
        }

        public static async Task<IHunk> ParseHunk(Stream stream)
        {
            var identifier = await stream.ReadUInt32();

            switch (identifier)
            {
                case HunkIdentifiers.Code:
                    return await ParseCode(stream);
                case HunkIdentifiers.ReLoc32:
                    return await ParseReLoc32(stream);
                case HunkIdentifiers.End:
                    return new End();
                default:
                    throw new IOException($"Unsupported hunk identifier '{identifier.FormatHex()}'");
            }
        }

        public static async Task<Header> ParseHeader(Stream stream)
        {
            var identifier = await stream.ReadUInt32();
            if (identifier != HunkIdentifiers.Header)
            {
                throw new IOException("Invalid hunk header identifier");
            }

            var residentLibraryNames = new List<string>();

            string residentLibraryName;
            do
            {
                residentLibraryName = await ReadString(stream);
                if (string.IsNullOrEmpty(residentLibraryName))
                {
                    break;
                }
                residentLibraryNames.Add(residentLibraryName);
            } while (!string.IsNullOrEmpty(residentLibraryName));
            
            var tableSize = await stream.ReadUInt32();
            var firstHunk = await stream.ReadUInt32();
            var lastHunk = await stream.ReadUInt32();

            var hunkSizes = new List<uint>();
            for (var i = 0; i < lastHunk - firstHunk + 1; i++)
            {
                hunkSizes.Add(await stream.ReadUInt32());
            }

            return new Header
            {
                ResidentLibraryNames = residentLibraryNames,
                TableSize = tableSize,
                FirstHunkSlot = firstHunk,
                LastHunkSlot = lastHunk,
                HunkSizes = hunkSizes
            };
        }

        public static async Task<Code> ParseCode(Stream stream)
        {
            var size = await stream.ReadUInt32();
            var data = await stream.ReadBytes((int)size * 4);

            return new Code
            {
                Data = data
            };
        }
        
        public static async Task<ReLoc32> ParseReLoc32(Stream stream)
        {
            var hunkOffsets = new List<uint>();

            do
            {
                var numOffsets = await stream.ReadUInt32();
                if (numOffsets == 0)
                {
                    break;
                }

                var hunkNumber = await stream.ReadUInt32();
                hunkOffsets.Add(hunkNumber);

                for (var i = 0; i < numOffsets; i++)
                {
                    var hunkOffset = await stream.ReadUInt32();
                    hunkOffsets.Add(hunkOffset);
                }
            } while (stream.Position < stream.Length);

            return new ReLoc32
            {
                Offsets = hunkOffsets
            };

            // // the number of offsets for a given hunk. If this value is zero, then it indicates the immediate end of this block.
            // var offsetCount = await stream.ReadUInt32();
            //
            // if (offsetCount == 0)
            // {
            //     return new ReLoc32();
            // }
            //
            // // The number of the hunk the offsets are to point into.
            // var hunkCount = await stream.ReadUInt32();
            //
            // var offsets = new List<uint>();
            // for (var i = 0; i < offsetCount; i++)
            // {
            //     // Offset in the current CODE or DATA hunk to relocate.
            //     var offset = await stream.ReadUInt32();
            //     offsets.Add(offset);
            // }
            //
            // return new ReLoc32
            // {
            //     Offsets = offsets
            // };
        }

        public static async Task<string> ReadString(Stream stream)
        {
            var numLongs = await stream.ReadUInt32();
            if (numLongs < 1)
                return null;

            var stringBytes = await stream.ReadBytes((int)numLongs * 4);

            var endOffset = stringBytes.Length - 1;
            for (var i = 0; i < stringBytes.Length; i++)
            {
                if (stringBytes[i] == '\0')
                {
                    endOffset = i;
                }
            }
            
            return Encoding.ASCII.GetString(stringBytes, 0, endOffset);
        }
    }
}