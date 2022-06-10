namespace HstWbInstaller.Core.IO.Lha
{
    using System;
    using System.IO;
    using System.Linq;
    using System.Text;
    using System.Threading.Tasks;
    using Extensions;

    // https://github.com/jca02266/lha/blob/ee44d88d7437dbe1a9153c369a844c85cf42683c/src/header.c
    public static class LhaHeaderReader
    {
        private const int I_HEADER_SIZE = 0;              /* level 0,1,2   */
        private const int I_HEADER_CHECKSUM = 1;               /* level 0,1     */
        private const int I_METHOD = 2;               /* level 0,1,2,3 */
        private const int I_PACKED_SIZE = 7;               /* level 0,1,2,3 */
        private const int I_ATTRIBUTE = 19;              /* level 0,1,2,3 */
        private const int I_HEADER_LEVEL = 20;              /* level 0,1,2,3 */

        private const int COMMON_HEADER_SIZE = 21;      /* size of common part */

        private const int I_GENERIC_HEADER_SIZE = 24; /* + name_length */
        private const int I_LEVEL0_HEADER_SIZE = 36; /* + name_length (unix extended) */
        private const int I_LEVEL1_HEADER_SIZE = 27; /* + name_length */
        private const int I_LEVEL2_HEADER_SIZE = 26; /* + padding */
        private const int I_LEVEL3_HEADER_SIZE = 32;

        public static async Task<LzHeader> GetHeader(Stream stream, Encoding encoding)
        {
            var headerOffset = stream.Position;
            var data = await stream.ReadBytes(I_HEADER_LEVEL + 1);

            if (data == null || data.Length == 0 || (data.Length == 1 && data[0] == 0))
            {
                return null;
            }

            switch (data[I_HEADER_LEVEL])
            {
                case 0:
                    return await GetHeaderLevel0(stream, headerOffset, data, encoding);
                case 1:
                    return await GetHeaderLevel1(stream, headerOffset, data, encoding);
                case 2:
                    return await GetHeaderLevel2(stream, headerOffset, data, encoding);
                case 3:
                    return await GetHeaderLevel3(stream, headerOffset, data, encoding);
                default:
                    throw new IOException("read header (level %x) is unknown", data[I_HEADER_LEVEL]);
            }
        }
        
        public static async Task<LzHeader> GetHeaderLevel0(Stream stream, long headerOffset, byte[] data, Encoding encoding)
        {
            var headerSize = data[0];
            var checksum = data[1];

            var remainSize = headerSize + 2 - COMMON_HEADER_SIZE;
            var remainingBytes = await stream.ReadBytes(remainSize);
            var headerBytes = data.Concat(remainingBytes).ToArray();
            
            if (remainSize <= 0)
            {
                throw new IOException("Invalid header size");
            }

            var headerReader = new BinaryReader(new MemoryStream(headerBytes));
            
            if (ChecksumHelper.CalcSum(headerBytes, I_METHOD, headerSize) != checksum)
            {
                throw new IOException("Checksum error");
            }

            var header = new LzHeader
            {
                SizeFieldLength = 2,
                HeaderSize = headerSize,
                HeaderOffset = headerOffset
            };
            
            headerReader.BaseStream.Seek(2, SeekOrigin.Begin);
            
            header.Method = Encoding.ASCII.GetString(headerReader.ReadBytes(5));
            header.PackedSize = headerReader.ReadInt32();
            header.OriginalSize = headerReader.ReadInt32();
            header.UnixLastModifiedStamp = headerReader.ReadInt32();
            header.Attribute = headerReader.ReadByte();
            header.HeaderLevel = headerReader.ReadByte();
            
            var nameLength = headerReader.ReadByte();
            header.Name = encoding.GetString(headerReader.ReadBytes(nameLength));

            /* defaults for other type */
            header.UnixMode = Constants.UNIX_FILE_REGULAR | Constants.UNIX_RW_RW_RW;
            header.UnixGid = 0;
            header.UnixGid = 0;

            var extendSize = headerSize + 2 - nameLength - 24;
            
            if (extendSize < 0)
            {
                if (extendSize == -2)
                {
                    /* CRC field is not given */
                    header.ExtendType = Constants.EXTEND_GENERIC;
                    header.HasCrc = false;

                    return header;
                }

                throw new IOException("Unknown header");
            }
            
            header.HasCrc = true;
            header.Crc = headerReader.ReadInt16();

            if (extendSize != 0)
            {
                header.ExtendType = headerReader.ReadByte();
                extendSize--;

                if (header.ExtendType == Constants.EXTEND_UNIX) {
                    if (extendSize >= 11) {
                        header.MinorVersion = headerReader.ReadByte();
                        header.UnixLastModifiedStamp = headerReader.ReadInt32();
                        header.UnixMode = headerReader.ReadInt16();
                        header.UnixUid = headerReader.ReadInt16();
                        header.UnixGid = headerReader.ReadInt16();
                        extendSize -= 11;
                    } else {
                        header.ExtendType = Constants.EXTEND_GENERIC;
                    }
                }

                if (extendSize > 0)
                {
                    headerReader.ReadBytes(extendSize);
                }
            }

            header.HeaderSize += 2;

            return header;
        }
        
        public static async Task<LzHeader> GetHeaderLevel1(Stream stream, long headerOffset, byte[] data, Encoding encoding)
        {
            var headerSize = data[0];
            var checksum = data[1];

            var remainSize = headerSize + 2 - COMMON_HEADER_SIZE;
            var remainingBytes = await stream.ReadBytes(remainSize);
            var headerBytes = data.Concat(remainingBytes).ToArray();
            
            if (remainSize <= 0)
            {
                throw new IOException("Invalid header size");
            }

            var headerReader = new BinaryReader(new MemoryStream(headerBytes));
            
            if (ChecksumHelper.CalcSum(headerBytes, I_METHOD, headerSize) != checksum)
            {
                throw new IOException("Checksum error");
            }

            var header = new LzHeader
            {
                SizeFieldLength = 2,
                HeaderSize = headerSize,
                HeaderOffset = headerOffset
            };
            
            headerReader.BaseStream.Seek(2, SeekOrigin.Begin);
            
            header.Method = Encoding.ASCII.GetString(headerReader.ReadBytes(5));
            header.PackedSize = headerReader.ReadInt32();
            header.OriginalSize = headerReader.ReadInt32();
            header.UnixLastModifiedStamp = headerReader.ReadInt32();
            header.Attribute = headerReader.ReadByte();
            header.HeaderLevel = headerReader.ReadByte();
            
            var nameLength = headerReader.ReadByte();
            header.Name = encoding.GetString(headerReader.ReadBytes(nameLength));
            
            /* defaults for other type */
            header.UnixMode = Constants.UNIX_FILE_REGULAR | Constants.UNIX_RW_RW_RW;
            header.UnixGid = 0;
            header.UnixGid = 0;
            
            header.HasCrc = true;
            header.Crc = headerReader.ReadInt16();
            header.ExtendType = headerReader.ReadByte();            
                
            var skipBytes = header.HeaderSize + 2 - nameLength - I_LEVEL1_HEADER_SIZE;
            if (skipBytes > 0)
            {
                await stream.ReadBytes(skipBytes); /* skip old style extend header */
            }
            
            var extendSize = (int)headerReader.ReadInt16();
            extendSize = await GetExtendedHeader(stream, header, extendSize, false, encoding);
            if (extendSize == -1)
            {
                throw new IOException();
            }

            /* On level 1 header, size fields should be adjusted. */
            /* the `packed_size' field contains the extended header size. */
            /* the `header_size' field does not. */
            header.PackedSize -= extendSize;
            header.HeaderSize += extendSize;
            header.HeaderSize += 2;
            
            return header;
        }
        
        public static async Task<LzHeader> GetHeaderLevel2(Stream stream, long headerOffset, byte[] data, Encoding encoding)
        {
            var headerSize = (data[1] << 8) + data[0];

            var remainSize = headerSize - I_LEVEL2_HEADER_SIZE;
            var remainingBytes = await stream.ReadBytes(remainSize);
            var headerBytes = data.Concat(remainingBytes).ToArray();
            
            if (remainSize <= 0)
            {
                throw new IOException("Invalid header size");
            }

            var header = new LzHeader
            {
                SizeFieldLength = 2,
                HeaderSize = headerSize,
                HeaderOffset = headerOffset
            };
            
            var headerReader = new BinaryReader(new MemoryStream(headerBytes));
            
            headerReader.BaseStream.Seek(2, SeekOrigin.Begin);
            
            header.Method = Encoding.ASCII.GetString(headerReader.ReadBytes(5));
            header.PackedSize = headerReader.ReadInt32();
            header.OriginalSize = headerReader.ReadInt32();
            header.UnixLastModifiedStamp = headerReader.ReadInt32();
            header.Attribute = headerReader.ReadByte();
            header.HeaderLevel = headerReader.ReadByte();
            
            /* defaults for other type */
            header.UnixMode = Constants.UNIX_FILE_REGULAR | Constants.UNIX_RW_RW_RW;
            header.UnixGid = 0;
            header.UnixUid = 0;

            header.HasCrc = true;
            header.Crc = headerReader.ReadInt16();
            header.ExtendType = headerReader.ReadByte();            
            var extendSize = (int)headerReader.ReadInt16();

            /*
            INITIALIZE_CRC(hcrc);
            hcrc = calccrc(hcrc, data, get_ptr - data);

            extend_size = get_extended_header(fp, hdr, extend_size, &hcrc);
            if (extend_size == -1)
                return FALSE;
            */
            
            extendSize = await GetExtendedHeader(stream, header, extendSize, false, encoding);
            if (extendSize == -1)
            {
                throw new IOException();
            }
            
            var padding = headerSize - I_LEVEL2_HEADER_SIZE - extendSize;
            /* padding should be 0 or 1 */
            if (padding != 0 && padding != 1) {
                throw new IOException($"Invalid header size (padding: {padding})");
            }

            // while (padding--)
            //     hcrc = UPDATE_CRC(hcrc, fgetc(fp));

            // if (hdr->header_crc != hcrc)
            //     error("header CRC error");

            return header;            
        }
        
        public static Task<LzHeader> GetHeaderLevel3(Stream stream, long headerOffset, byte[] data, Encoding encoding)
        {
            throw new NotSupportedException("Header level 3 not supported");
        }
        
        public static async Task<int> GetExtendedHeader(Stream stream, LzHeader header, int headerSize,
            bool hasCrc, Encoding encoding)
        {
            if (header.HeaderLevel == 0)
            {
                return 0;
            }

            var extendedHeaderSize = 0;
            var n = 1 + header.SizeFieldLength; /* `ext-type' + `next-header size' */
            string directory = null;
            
            while (headerSize > 0)
            {
                extendedHeaderSize += headerSize;
                
                var data = await stream.ReadBytes(headerSize);
                var dataReader = new BinaryReader(new MemoryStream(data));
                var extType = dataReader.ReadByte();
                
                switch (extType)
                {
                    case 0:
                        /* header crc (CRC-16) */
                        header.HeaderCrc = dataReader.ReadInt16();
                        /* clear buffer for CRC calculation. */
                        data[1] = data[2] = 0;
                        dataReader.ReadBytes(headerSize - n - 2);
                        break;
                    case 1:
                        // filename
                        header.Name = encoding.GetString(dataReader.ReadBytes(headerSize - n - 1));
                        dataReader.ReadByte();
                        break;
                    case 2:
                        // directory
                        var directoryBytes = dataReader.ReadBytes(headerSize - n);
                        for (var i = 0; i < directoryBytes.Length; i++)
                        {
                            if (directoryBytes[i] == 255)
                            {
                                directoryBytes[i] = (byte)'\\';
                            }
                        }
                        directory = encoding.GetString(directoryBytes);
                        break;
                    case 0x40:
                        // MS-DOS attribute
                        header.Attribute = dataReader.ReadInt16();
                        break;
                    case 0x41:
                        /* Windows time stamp (FILETIME structure) */
                        /* it is time in 100 nano seconds since 1601-01-01 00:00:00 */

                        dataReader.ReadBytes(8); /* create time is ignored */

                        /* set last modified time */
                        if (header.HeaderLevel >= 2)
                        {
                            dataReader.ReadBytes(8);  /* time_t has been already set */
                        }
                        else
                        {
                            //header.LastModifiedStamp = wintime_to_unix_stamp();
                        }

                        dataReader.ReadBytes(8); /* last access time is ignored */                        
                        break;
                    case 0x42:
                        /* 64bits file size header (UNLHA32 extension) */
                        header.PackedSize = dataReader.ReadInt64();
                        header.OriginalSize = dataReader.ReadInt64();
                        break;
                    case 0x50:
                        /* UNIX permission */
                        header.UnixMode = dataReader.ReadInt16();                        
                        break;
                    case 0x51:
                        /* UNIX gid and uid */
                        header.UnixGid = dataReader.ReadInt16();
                        header.UnixUid = dataReader.ReadInt16();                        
                        break;
                    case 0x52:
                        /* UNIX group name */
                        header.UnixGroupName = encoding.GetString(dataReader.ReadBytes(headerSize - n - 1));
                        dataReader.ReadByte();
                        break;
                    case 0x53:
                        /* UNIX user name */
                        header.UnixUserName = encoding.GetString(dataReader.ReadBytes(headerSize - n - 1));
                        dataReader.ReadByte();
                        break;
                    case 0x54:
                        header.UnixLastModifiedStamp = dataReader.ReadInt32();
                        break;
                    default:
                        dataReader.ReadBytes(headerSize - n);
                        break;
                }
                
                // if (hcrc)
                //     *hcrc = calccrc(*hcrc, data, headerSize);
                //
                
                if (header.SizeFieldLength == 2)
                {
                    headerSize = dataReader.ReadInt16();
                }
                else
                {
                    headerSize = dataReader.ReadInt32();
                }
            }

            if (!string.IsNullOrWhiteSpace(directory))
            {
                header.Name = string.Concat(directory, header.Name);
            }

            return extendedHeaderSize;
        }
    }
}