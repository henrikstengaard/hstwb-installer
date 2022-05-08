namespace HstWbInstaller.Core.IO.FastFileSystem
{
    using System;
    using System.IO;
    using System.Threading;
    using System.Threading.Tasks;

    public class EntryStream : Stream
    {
        private readonly Volume volume;

        private readonly int length;

        private bool eof;
        private readonly FileHeaderBlock fileHdr;

        private uint pos;
        private uint posInExtBlk;
        private uint posInDataBlk;
        private uint curDataPtr;
        private FileExtBlock currentExt;
        private uint nDataBlock = 0;
        private IDataBlock currentData;
        private bool writeMode;

        public EntryStream(Volume volume, bool writeMode, bool eof, FileHeaderBlock fhdr)
        {
            this.volume = volume;
            this.writeMode = writeMode;
            this.length = length;
            this.eof = eof;
            this.fileHdr = fhdr;
            this.pos = 0;
            this.posInExtBlk = 0;
            this.posInDataBlk = 0;
            this.currentData = new DataBlock
            {
                Data = new byte[volume.DataBlockSize]
            };
        }

        public override async ValueTask DisposeAsync()
        {
            await AdfCloseFile();
            await base.DisposeAsync();
        }

        protected override void Dispose(bool disposing)
        {
            AdfCloseFile().GetAwaiter().GetResult();
            base.Dispose(disposing);
        }

        public override void Flush()
        {
            AdfFlushFile().GetAwaiter().GetResult();
        }

        public override async Task FlushAsync(CancellationToken cancellationToken)
        {
            await AdfFlushFile();
        }

        public override int Read(byte[] buffer, int offset, int count)
        {
            if (offset != 0)
            {
                throw new ArgumentException("Only offset 0 is supported", nameof(offset));
            }

            return AdfReadFile(count, buffer).GetAwaiter().GetResult();
        }

        public override async Task<int> ReadAsync(byte[] buffer, int offset, int count,
            CancellationToken cancellationToken)
        {
            if (offset != 0)
            {
                throw new ArgumentException("Only offset 0 is supported", nameof(offset));
            }

            return await AdfReadFile(count, buffer);
        }

        public override long Seek(long offset, SeekOrigin origin)
        {
            AdfFileSeek((uint)offset).GetAwaiter().GetResult();
            return 0;
        }

        public override void SetLength(long value)
        {
            throw new IOException(
                "Set length not supported for entries. Use write buffer instead with buffer set to length");
        }

        public override void Write(byte[] buffer, int offset, int count)
        {
            if (offset != 0)
            {
                throw new ArgumentException("Only offset 0 is supported", nameof(offset));
            }

            AdfWriteFile(count, buffer).GetAwaiter().GetResult();
        }

        public override async Task WriteAsync(byte[] buffer, int offset, int count, CancellationToken cancellationToken)
        {
            if (offset != 0)
            {
                throw new ArgumentException("Only offset 0 is supported", nameof(offset));
            }

            await AdfWriteFile(count, buffer);
        }

        public override bool CanRead => true;
        public override bool CanSeek => true;
        public override bool CanWrite => writeMode;
        public override long Length => length;
        public override long Position { get; set; }

        private async Task AdfFileSeek(uint pos)
        {
            //SECTNUM extBlock, nSect;
            //uint32_t nPos;
            int i;

            var nPos = (int)Math.Min(pos, length);
            this.pos = (uint)nPos;
            var extBlock = Pos2DataBlock(nPos);
            if (extBlock == -1)
            {
                currentData =
                    await File.AdfReadDataBlock(volume, fileHdr.DataBlocks[Constants.MAX_DATABLK - 1 - curDataPtr]);
                // adfReadDataBlock(file->volume,
                //     file->fileHdr->dataBlocks[MAX_DATABLK-1-file->curDataPtr],
                //     file->currentData);
            }
            else
            {
                var nSect = fileHdr.Extension;
                i = 0;
                while (i < extBlock && nSect != 0)
                {
                    currentExt = await File.AdfReadFileExtBlock(volume, nSect);
                    nSect = currentExt.extension;
                }

                if (i != extBlock)
                {
                    throw new IOException("error");
                }

                currentData = await File.AdfReadDataBlock(volume, currentExt.dataBlocks[posInExtBlk]);
            }
        }

        /*
        * adfPos2DataBlock
            *
            */
        private int Pos2DataBlock(int position) //, int *posInExtBlk, int *posInDataBlk, int32_t *curDataN )
        {
            posInDataBlk = (uint)(position % volume.BlockSize);
            curDataPtr = (uint)(position / volume.BlockSize);
            if (posInDataBlk == 0)
                curDataPtr++;
            if (curDataPtr < 72)
            {
                posInExtBlk = 0;
                return -1;
            }

            posInExtBlk = (uint)((position - 72 * volume.BlockSize) % volume.BlockSize);
            var extBlock = (int)((position - 72 * volume.BlockSize) / volume.BlockSize);
            if (posInExtBlk == 0)
                extBlock++;
            return extBlock;
        }

/*
 * adfReadFile
 *
 */
        private async Task<int> AdfReadFile(int n, byte[] buffer)
        {
            // https://github.com/lclevy/ADFlib/blob/be8a6f6e8d0ca8fda963803eef77366c7584649a/src/adf_file.c#L369

            //uint8_t *dataPtr, *bufPtr;

            if (n > buffer.Length)
            {
                throw new ArgumentOutOfRangeException(nameof(n),
                    $"Count '{n}' is larger than buffer size '{buffer.Length}'");
            }

            if (n == 0)
                return n;
            var blockSize = volume.DataBlockSize;
/*puts("adfReadFile");*/
            if (pos + n > fileHdr.ByteSize)
                n = (int)(fileHdr.ByteSize - pos);


            if (pos == 0 || posInDataBlk == blockSize)
            {
                await AdfReadNextFileBlock();
                posInDataBlk = 0;
            }

            var dataPtr = currentData.Data;

            // if (Macro.isOFS(volume.DosType))
            // {
            //     var ofsCurrentData = new byte[currentData.BlockBytes.Length - 24];
            //     Array.Copy(currentData.BlockBytes);
            //     dataPtr = (uint8_t*)(file->currentData)+24;
            // }
            // else
            // {
            //     dataPtr = currentData.BlockBytes;
            // }

            var bytesRead = 0;
            // bufPtr = buffer;
            var bufPtr = 0;
            while (bytesRead < n)
            {
                var size = (int)Math.Min(n - bytesRead, blockSize - posInDataBlk);

                // memcpy(bufPtr, dataPtr+file->posInDataBlk, size);
                Array.Copy(dataPtr, posInDataBlk, buffer, bufPtr, size);
                bufPtr += size;
                pos += (uint)size;
                bytesRead += size;
                posInDataBlk += (uint)size;
                if (posInDataBlk == blockSize && bytesRead < n)
                {
                    await AdfReadNextFileBlock();
                    posInDataBlk = 0;
                }
            }

            eof = pos == fileHdr.ByteSize;
            return bytesRead;
        }

/*
 * adfReadNextFileBlock
 *
 */
        public async Task AdfReadNextFileBlock()
        {
            int nSect;
            // struct bOFSDataBlock *data;
            // RETCODE rc = RC_OK;

            // data =(struct bOFSDataBlock *) currentData;
            var data = currentData as OfsDataBlock;
            //
            // if (data == null)
            // {
            //     throw new IOException("currentData is not OFSDataBlock");
            // }

            if (nDataBlock == 0)
            {
                nSect = fileHdr.FirstData;
            }
            else if (Macro.isOFS(volume.DosType))
            {
                nSect = data.NextData;
            }
            else
            {
                if (nDataBlock < Constants.MAX_DATABLK)
                    nSect = fileHdr.DataBlocks[Constants.MAX_DATABLK - 1 - nDataBlock];
                else
                {
                    if (nDataBlock == Constants.MAX_DATABLK)
                    {
                        // file->currentExt=(struct bFileExtBlock*)malloc(sizeof(struct bFileExtBlock));
                        // if (!file->currentExt) (*adfEnv.eFct)("adfReadNextFileBlock : malloc");
                        currentExt = await File.AdfReadFileExtBlock(volume, fileHdr.Extension);
                        posInExtBlk = 0;
                    }
                    else if (posInExtBlk == Constants.MAX_DATABLK)
                    {
                        currentExt = await File.AdfReadFileExtBlock(volume, currentExt.extension);
                        posInExtBlk = 0;
                    }

                    nSect = currentExt.dataBlocks[Constants.MAX_DATABLK - 1 - posInExtBlk];
                    posInExtBlk++;
                }
            }

            // AdfReadDataBlock(volume,nSect,file->currentData);
            currentData = await File.AdfReadDataBlock(volume, nSect);

            if (Macro.isOFS(volume.DosType) && data.SeqNum != nDataBlock + 1)
                throw new IOException("adfReadNextFileBlock : seqnum incorrect");

            nDataBlock++;
        }

/*
 * adfWriteFile
 *
 */
        public async Task<int> AdfWriteFile(int n, byte[] buffer)
        {
            // int32_t bytesWritten;
            // uint8_t *dataPtr, *bufPtr;
            // int size, blockSize;
            // struct bOFSDataBlock *dataB;

            var bytesWritten = 0;
            if (n == 0) return n;
/*puts("adfWriteFile");*/
            var blockSize = volume.DataBlockSize;
            var dataPtr = currentData.Data;
            //
            // if (Macro.isOFS(volume.DosType))
            // {
            //     dataB =(struct bOFSDataBlock *)file->currentData;
            //     dataPtr = dataB->data;
            // }
            // else
            //     dataPtr = currentData;

            if (pos == 0 || posInDataBlk == blockSize)
            {
                if (await AdfCreateNextFileBlock() == -1)
                {
                    /* bug found by Rikard */
                    throw new IOException("adfWritefile : no more free sector availbale");
                }

                posInDataBlk = 0;
            }

            bytesWritten = 0;
            var bufPtr = 0;
            while (bytesWritten < n)
            {
                var size = (int)Math.Min(n - bytesWritten, blockSize - posInDataBlk);

                // memcpy(dataPtr+file->posInDataBlk, bufPtr, size);
                Array.Copy(buffer, bufPtr, dataPtr, posInDataBlk, size);

                bufPtr += size;
                pos += (uint)size;
                bytesWritten += size;
                posInDataBlk += (uint)size;
                if (posInDataBlk == blockSize && bytesWritten < n)
                {
                    if (await AdfCreateNextFileBlock() == -1)
                    {
                        /* bug found by Rikard */
                        throw new IOException("adfWritefile : no more free sector available");
                    }

                    posInDataBlk = 0;
                }
            }

            return bytesWritten;
        }

        /*
 * adfCreateNextFileBlock
 *
 */
        public async Task<int> AdfCreateNextFileBlock()
        {
            //    SECTNUM nSect, extSect;
            //    struct bOFSDataBlock *data;
            // unsigned int blockSize;
            //    int i;
/*puts("adfCreateNextFileBlock");*/
            var nSect = 0;
            var blockSize = volume.DataBlockSize;

            /* the first data blocks pointers are inside the file header block */
            if (nDataBlock < Constants.MAX_DATABLK)
            {
                nSect = Bitmap.AdfGet1FreeBlock(volume);
                if (nSect == -1) return -1;
/*printf("adfCreateNextFileBlock fhdr %ld\n",nSect);*/
                if (nDataBlock == 0)
                    fileHdr.FirstData = nSect;
                fileHdr.DataBlocks[Constants.MAX_DATABLK - 1 - nDataBlock] = nSect;
                fileHdr.HighSeq++;
            }
            else
            {
                /* one more sector is needed for one file extension block */
                if (nDataBlock % Constants.MAX_DATABLK == 0)
                {
                    var extSect = Bitmap.AdfGet1FreeBlock(volume);
/*printf("extSect=%ld\n",extSect);*/
                    if (extSect == -1) return -1;

                    /* the future block is the first file extension block */
                    if (nDataBlock == Constants.MAX_DATABLK)
                    {
                        currentExt = new FileExtBlock();
                        // file->currentExt=(struct bFileExtBlock*)malloc(sizeof(struct bFileExtBlock));
                        // if (!file->currentExt) {
                        //     adfSetBlockFree(file->volume, extSect);
                        //     (*adfEnv.eFct)("adfCreateNextFileBlock : malloc");
                        //     return -1;
                        // }
                        fileHdr.Extension = extSect;
                    }

                    /* not the first : save the current one, and link it with the future */
                    if (nDataBlock >= 2 * Constants.MAX_DATABLK)
                    {
                        currentExt.extension = extSect;
/*printf ("write ext=%d\n",file->currentExt->headerKey);*/
                        await File.AdfWriteFileExtBlock(volume, currentExt.headerKey, currentExt);
                    }

                    /* initializes a file extension block */
                    for (var i = 0; i < Constants.MAX_DATABLK; i++)
                        currentExt.dataBlocks[i] = 0;
                    currentExt.headerKey = extSect;
                    currentExt.parent = fileHdr.HeaderKey;
                    currentExt.highSeq = 0;
                    currentExt.extension = 0;
                    posInExtBlk = 0;
/*printf("extSect=%ld\n",extSect);*/
                }

                nSect = Bitmap.AdfGet1FreeBlock(volume);
                if (nSect == -1)
                    return -1;

/*printf("adfCreateNextFileBlock ext %ld\n",nSect);*/

                currentExt.dataBlocks[Constants.MAX_DATABLK - 1 - posInExtBlk] = nSect;
                currentExt.highSeq++;
                posInExtBlk++;
            }

            //var data = currentData;

            /* builds OFS header */
            if (Macro.isOFS(volume.DosType))
            {
                var data = currentData as OfsDataBlock;
                /* writes previous data block and link it  */
                if (pos >= blockSize)
                {
                    data.NextData = nSect;
                    await File.AdfWriteDataBlock(volume, (int)curDataPtr, currentData);
/*printf ("writedata=%d\n",file->curDataPtr);*/
                }

                /* initialize a new data block */
                for (var i = 0; i < blockSize; i++)
                    data.Data[i] = 0;
                data.SeqNum = (int)(nDataBlock + 1);
                data.DataSize = blockSize;
                data.NextData = 0;
                data.HeaderKey = fileHdr.HeaderKey;
            }
            else if (pos >= blockSize)
            {
                await File.AdfWriteDataBlock(volume, (int)curDataPtr, currentData);
/*printf ("writedata=%d\n",file->curDataPtr);*/
                //memset(file->currentData, 0, 512);
            }

/*printf("datablk=%d\n",nSect);*/
            curDataPtr = (uint)nSect;
            nDataBlock++;

            return nSect;
        }
        
        /*
 * adfCloseFile
 *
 */
        public async Task AdfCloseFile()
        {
            // if (file==0)
            //     return;
/*puts("adfCloseFile in");*/

            await AdfFlushFile();
            //
            // if (file->currentExt)
            //     free(file->currentExt);
            //
            // if (file->currentData)
            //     free(file->currentData);
            //
            // free(file->fileHdr);
            // free(file);

/*puts("adfCloseFile out");*/
        }
        
/*
 * adfFileFlush
 *
 */
        public async Task AdfFlushFile()
        {
            // struct bEntryBlock parent;
            // struct bOFSDataBlock *data;

            if (currentExt != null) 
            {
                if (writeMode)
                    await File.AdfWriteFileExtBlock(volume, currentExt.headerKey, currentExt);
            }
            if (currentData != null)
            {
                if (writeMode)
                {
                    fileHdr.ByteSize = (int)pos;
                    if (Macro.isOFS(volume.DosType))
                    {
                        var data = currentData as OfsDataBlock;
                        data.DataSize = (int)posInDataBlk;
                    }
                    if (fileHdr.ByteSize > 0)
                        await File.AdfWriteDataBlock(volume, (int)curDataPtr, currentData);
                }
            }
            if (writeMode)
            {
                fileHdr.ByteSize = (int)pos;
/*printf("pos=%ld\n",file->pos);*/
                // adfTime2AmigaTime(adfGiveCurrentTime(),
                //     &(file->fileHdr->days),&(file->fileHdr->mins),&(file->fileHdr->ticks) );
                fileHdr.Date = DateTime.Now;
                await File.AdfWriteFileHdrBlock(volume, fileHdr.HeaderKey, fileHdr);

                if (Macro.isDIRCACHE(volume.DosType)) 
                {
/*printf("parent=%ld\n",file->fileHdr->parent);*/
                    var parent = await Disk.AdfReadEntryBlock(volume, fileHdr.Parent);
                    Cache.AdfUpdateCache(volume, parent, fileHdr, true);
                }
                await Bitmap.AdfUpdateBitmap(volume);
            }
        }        
    }
}