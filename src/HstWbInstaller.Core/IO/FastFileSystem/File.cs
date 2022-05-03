namespace HstWbInstaller.Core.IO.FastFileSystem
{
    using System.IO;
    using System.Threading.Tasks;

    public static class File
    {
        public static async Task<Stream> Open(Volume volume, IEntryBlock parent, string name, FileMode mode)
        {
            // https://github.com/lclevy/ADFlib/blob/be8a6f6e8d0ca8fda963803eef77366c7584649a/src/adf_file.c#L265

            var write = mode is FileMode.Write or FileMode.Append;

            if (!volume.Stream.CanWrite && write)
            {
                throw new IOException("device is mounted 'read only'");
            }

            // adfReadEntryBlock(vol, vol->curDirPtr, &parent);
            // skipped as parent is provided as argument

            var result = await Directory.AdfNameToEntryBlk(volume, parent.HashTable, name, false);
            var nSect = result.NSect;
            if (!write && nSect == -1)
            {
                // sprintf(filename,"adfFileOpen : file \"%s\" not found.",name);
                // (*adfEnv.wFct)(filename);
                if (!volume.IgnoreErrors)
                {
                    throw new IOException($"file \"{name}\" not found.");
                }
                volume.Logs.Add($"ERROR: File \"{name}\" not found.");
/*fprintf(stdout,"filename %s %d, parent =%d\n",name,strlen(name),vol->curDirPtr);*/
                //return null; 
            }

            if (result.EntryBlock == null)
            {
                if (!volume.IgnoreErrors)
                {
                    throw new IOException($"file \"{name}\" has no entry block.");
                }

                volume.Logs.Add($"ERROR: File \"{name}\" has no entry block.");
                return null;
            }

            var entry = result.EntryBlock;
            if (!write && Macro.hasR(entry.Access))
            {
                throw new IOException("access denied");
            }

            // (*adfEnv.wFct)("adfFileOpen : access denied"); return NULL; }
/*    if (entry.secType!=ST_FILE) {
        (*adfEnv.wFct)("adfFileOpen : not a file"); return NULL; }
	if (write && (hasE(entry.access)||hasW(entry.access))) {
        (*adfEnv.wFct)("adfFileOpen : access denied"); return NULL; }  
*/
            if (write && nSect == -1)
            {
                //(*adfEnv.wFct)("adfFileOpen : file already exists"); return NULL;
                throw new IOException("file already exists");
            }

            // file = (struct File*)malloc(sizeof(struct File));
            // if (!file) { (*adfEnv.wFct)("adfFileOpen : malloc"); return NULL; }
            // file->fileHdr = (struct bFileHeaderBlock*)malloc(sizeof(struct bFileHeaderBlock));
            // if (!file->fileHdr) {
            //     (*adfEnv.wFct)("adfFileOpen : malloc"); 
            //     free(file); return NULL; 
            // }
            // file->currentData = malloc(512*sizeof(uint8_t));
            // if (!file->currentData) { 
            //     (*adfEnv.wFct)("adfFileOpen : malloc"); 
            //     free(file->fileHdr); free(file); return NULL; 
            // }
            var fileHdr = await FileHeaderBlockReader.Parse(entry.BlockBytes);

            var eof = mode == FileMode.Write || mode == FileMode.Append;
            // switch (mode)
            // {
            //     case FileMode.Write:
            //         adfCreateFile(vol,vol->curDirPtr,name,file->fileHdr);
            //         eof = true;
            //         break;
            //     case FileMode.Append:
            //         eof = true;
            //         adfFileSeek(file, file->fileHdr->byteSize);
            //         break;
            // }

            var entryStream = new EntryStream(volume, write, eof, fileHdr);
            //var entryStream = new EntryStream(volume, write, eof, fileHdr);

            switch (mode)
            {
                case FileMode.Write:
                    await Directory.AdfCreateFile(volume, parent.HeaderKey, name);
                    eof = true;
                    break;
                case FileMode.Append:
                    entryStream.Seek(entry.ByteSize, SeekOrigin.Begin);
                    break;
            }

            return entryStream;
        }

/*
 * adfFileSeek
 *
 */


/*
 * adfReadDataBlock
 *
 */
        public static async Task<IDataBlock> AdfReadDataBlock(Volume vol, int nSect)
        {
            // https://github.com/lclevy/ADFlib/blob/be8a6f6e8d0ca8fda963803eef77366c7584649a/src/adf_file.c#L654

            // var buf = new byte[512];
            // struct bOFSDataBlock *dBlock;
            // RETCODE rc = RC_OK;

            var buf = await Disk.AdfReadBlock(vol, nSect);

            // memcpy(data,buf,512);

            if (Macro.isOFS(vol.DosType))
            {
// #ifdef LITT_ENDIAN
//                 swapEndian(data, SWBL_DATA);
// #endif
//                 dBlock = (struct bOFSDataBlock*)data;
/*printf("adfReadDataBlock %ld\n",nSect);*/

                var dBlock = await OfsDataBlockReader.Parse(buf);

                if (dBlock.CheckSum != Raw.AdfNormalSum(buf, 20, buf.Length))
                    throw new IOException("adfReadDataBlock : invalid checksum");
                if (dBlock.Type != Constants.T_DATA)
                    throw new IOException("adfReadDataBlock : id T_DATA not found");
                if (dBlock.DataSize < 0 || dBlock.DataSize > 488)
                    throw new IOException("adfReadDataBlock : dataSize incorrect");
                if (!Disk.IsSectNumValid(vol, dBlock.HeaderKey))
                    throw new IOException("adfReadDataBlock : headerKey out of range");
                if (!Disk.IsSectNumValid(vol, dBlock.NextData))
                    throw new IOException("adfReadDataBlock : nextData out of range");

                return dBlock;
            }

            return new DataBlock
            {
                BlockBytes = buf,
                Data = buf
            };
        }

/*
 * adfReadFileExtBlock
 *
 */
        public static async Task<FileExtBlock> AdfReadFileExtBlock(Volume vol, int nSect)
        {
            // uint8_t buf[sizeof(struct bFileExtBlock)];
            // RETCODE rc = RC_OK;

            var buf = await Disk.AdfReadBlock(vol, nSect);
/*printf("read fext=%d\n",nSect);*/
//             memcpy(fext,buf,sizeof(struct bFileExtBlock));
// #ifdef LITT_ENDIAN
//             swapEndian((uint8_t*)fext, SWBL_FEXT);
// #endif
            var fext = await FileExtBlockReader.Parse(buf);

            if (fext.checkSum != Raw.AdfNormalSum(buf, 20, buf.Length))
            {
                if (!vol.IgnoreErrors)
                {
                    throw new IOException("adfReadFileExtBlock : invalid checksum");
                }

                vol.Logs.Add($"ERROR: Sector '{nSect}', invalid checksum");
            }

            if (fext.type != Constants.T_LIST)
            {
                if (!vol.IgnoreErrors)
                {
                    throw new IOException("adfReadFileExtBlock : type T_LIST not found");
                }
                vol.Logs.Add($"ERROR: Sector '{nSect}', type T_LIST not found");
            }

            if (fext.secType != Constants.ST_FILE)
            {
                if (!vol.IgnoreErrors)
                {
                    throw new IOException("adfReadFileExtBlock : stype  ST_FILE not found");
                }
                vol.Logs.Add($"ERROR: Sector '{nSect}', stype  ST_FILE not found");
            }
            
            if (fext.headerKey != nSect)
                throw new IOException("adfReadFileExtBlock : headerKey!=nSect");
            if (fext.highSeq < 0 || fext.highSeq > Constants.MAX_DATABLK)
                throw new IOException("adfReadFileExtBlock : highSeq out of range");
            if (!Disk.IsSectNumValid(vol, fext.parent))
                throw new IOException("adfReadFileExtBlock : parent out of range");
            if (fext.extension != 0 && !Disk.IsSectNumValid(vol, fext.extension))
                throw new IOException("adfReadFileExtBlock : extension out of range");

            return fext;
        }

/*
 * adfWriteFileHdrBlock
 *
 */
        public static async Task AdfWriteFileHdrBlock(Volume vol, int nSect, FileHeaderBlock fhdr)
        {
            // uint8_t buf[512];
            // uint32_t newSum;
            // RETCODE rc = RC_OK;

/*printf("adfWriteFileHdrBlock %ld\n",nSect);*/
            fhdr.type = Constants.T_HEADER;
            fhdr.dataSize = 0;
            fhdr.secType = Constants.ST_FILE;

//             memcpy(buf, fhdr, sizeof(struct bFileHeaderBlock));
// #ifdef LITT_ENDIAN
//             swapEndian(buf, SWBL_FILE);
// #endif
            var buf = await FileHeaderBlockWriter.BuildBlock(fhdr, vol.BlockSize);
            // var newSum = Raw.AdfNormalSum(buf, 20, buf.Length);
            //swLong(buf+20, newSum);
            // newSum applied part of build block

/*    *(uint32_t*)(buf+20) = swapLong((uint8_t*)&newSum);*/

            await Disk.AdfWriteBlock(vol, nSect, buf);
        }
    }
}