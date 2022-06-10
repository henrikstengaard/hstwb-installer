namespace HstWbInstaller.Core.IO.Lha.Decode
{
    using System.IO;

    public static class LzhRead
    {
        public static byte[] archive_read_ahead(Stream stream, int min, ref long bytes_avail)
        {
            // min is length it has to read as minimum
            
            var buffer = new byte[4096];
            var bytesRead = stream.Read(buffer, 0, buffer.Length);
            bytes_avail = bytesRead;
            return buffer;
        }
        
        public static int archive_read_format_lha_read_data(lha_data lha, out byte[] buff, out long size, out long offset)
        {
            buff = null;
            size = 0;
            offset = 0;
            int r;

            if (lha.entry_unconsumed != 0) {
                /* Consume as much as the decompressor actually used. */
                //__archive_read_consume(a, lha.entry_unconsumed);
                lha.entry_unconsumed = 0;
            }
            if (lha.end_of_entry) {
                // *offset = lha.entry_offset;
                // *size = 0;
                // *buff = NULL;
                // return (lha_end_of_entry(a));
                return Constants.ARCHIVE_EOF;
            }

            if (lha.entry_is_compressed)
                r =  lha_read_data_lzh(lha, out buff, out size, out offset);
            else
                /* No compression. */
                r =  lha_read_data_none(lha, out buff, out size, out offset);
            return r;
        }
       
/*
 * Read a file content in no compression.
 *
 * Returns ARCHIVE_OK if successful, ARCHIVE_FATAL otherwise, sets
 * lha->end_of_entry if it consumes all of the data.
 */
        public static int lha_read_data_none(lha_data lha, out byte[] buff, out long size, out long offset)
        {
            buff = null;
            size = 0;
            offset = 0;
            long bytes_avail = 0;

            if (lha.entry_bytes_remaining == 0) {
                offset = lha.entry_offset;
                lha.end_of_entry = true;
                return Constants.ARCHIVE_OK;
            }
            /*
             * Note: '1' here is a performance optimization.
             * Recall that the decompression layer returns a count of
             * available bytes; asking for more than that forces the
             * decompressor to combine reads by copying data.
             */
            buff = archive_read_ahead(lha.stream, 1, ref bytes_avail);
            if (bytes_avail <= 0)
            {
                //archive_set_error(&a->archive, ARCHIVE_ERRNO_FILE_FORMAT,"Truncated LHa file data");
                return Constants.ARCHIVE_FATAL;
            }
            if (bytes_avail > lha.entry_bytes_remaining)
                bytes_avail = lha.entry_bytes_remaining;
            // lha->entry_crc_calculated = lha_crc16(lha->entry_crc_calculated, *buff, bytes_avail);
            size = bytes_avail;
            offset = lha.entry_offset;
            lha.entry_offset += bytes_avail;
            lha.entry_bytes_remaining -= bytes_avail;
            if (lha.entry_bytes_remaining == 0)
                lha.end_of_entry = true;
            lha.entry_unconsumed = bytes_avail;
            return Constants.ARCHIVE_OK;
        }        
/*
 * Read a file content in LZHUFF encoding.
 *
 * Returns ARCHIVE_OK if successful, returns ARCHIVE_WARN if compression is
 * unsupported, ARCHIVE_FATAL otherwise, sets lha->end_of_entry if it consumes
 * all of the data.
 */
        public static int lha_read_data_lzh(lha_data lha, out byte[] buff, out long size, out long offset)
        {
            buff = null;
            size = 0;
            offset = 0;
            
            //struct lha *lha = (struct lha *)(a->format->data);
            long bytes_avail = 0;
            int r;

            /* If we haven't yet read any data, initialize the decompressor. */
            if (!lha.decompress_init)
            {
                r = LzhDecode.lzh_decode_init(lha.strm, lha.method);
                switch (r)
                {
                    case Constants.ARCHIVE_OK:
                        break;
                    case Constants.ARCHIVE_FAILED:
                        throw new IOException("Unsupported compression");
                        /* Unsupported compression. */
                        /*
                        *buff = NULL;
                        *size = 0;
                        *offset = 0;
                        archive_set_error(&a.archive,
                            ARCHIVE_ERRNO_FILE_FORMAT,
                            "Unsupported lzh compression method -%c%c%c-",
                            lha.method[0], lha.method[1], lha.method[2]);
                        // We know compressed size; just skip it.
                        archive_read_format_lha_read_data_skip(a);
                        */
                        return Constants.ARCHIVE_WARN;
                    default:
                        //archive_set_error(&a.archive, ENOMEM, "Couldn't allocate memory ""for lzh decompression");
                        return Constants.ARCHIVE_FATAL;
                }

                /* We've initialized decompression for this stream. */
                lha.decompress_init = true;
                lha.strm.avail_out = 0;
                lha.strm.total_out = 0;
            }

            /*
             * Note: '1' here is a performance optimization.
             * Recall that the decompression layer returns a count of
             * available bytes; asking for more than that forces the
             * decompressor to combine reads by copying data.
             */
            //lha.strm.next_in = __archive_read_ahead(a, 1, bytes_avail);
            lha.strm.next_in = archive_read_ahead(lha.stream, 1, ref bytes_avail);
            if (bytes_avail <= 0)
            {
                //archive_set_error(&a.archive, ARCHIVE_ERRNO_FILE_FORMAT,"Truncated LHa file body");
                return Constants.ARCHIVE_FATAL;
            }

            if (bytes_avail > lha.entry_bytes_remaining)
                bytes_avail = lha.entry_bytes_remaining;

            lha.strm.avail_in = (int)bytes_avail;
            lha.strm.total_in = 0;
            lha.strm.avail_out = 0;

            r = LzhDecode.lzh_decode(lha.strm, bytes_avail == lha.entry_bytes_remaining);
            switch (r)
            {
                case Constants.ARCHIVE_OK:
                    break;
                case Constants.ARCHIVE_EOF:
                    lha.end_of_entry = true;
                    break;
                default:
                    //archive_set_error(&a.archive, ARCHIVE_ERRNO_MISC, "Bad lzh data");
                    return Constants.ARCHIVE_FAILED;
            }

            lha.entry_unconsumed = lha.strm.total_in;
            lha.entry_bytes_remaining -= lha.strm.total_in;

            if (lha.strm.avail_out != 0)
            {
                buff = lha.strm.ref_ptr;
                offset = lha.entry_offset;
                size = lha.strm.avail_out;
                // *buff = lha.strm.ref_ptr;
                // lha.entry_crc_calculated = lha_crc16(lha.entry_crc_calculated, *buff, *size);
                // lha.entry_offset += *size;
            }
            else
            {
                offset = lha.entry_offset;
                size = 0;
                buff = null;
                if (lha.end_of_entry)
                    return Constants.ARCHIVE_EOF;
                //return (lha_end_of_entry(a));
            }

            return Constants.ARCHIVE_OK;
        }
    }
}