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
                
        public EntryStream(Volume volume, bool writeMode, bool eof, FileHeaderBlock fhdr)
        {
            this.volume = volume;
            this.CanWrite = writeMode;
            this.length = length;
            this.eof = eof;
            this.fileHdr = fhdr;
            this.pos = 0;
            this.posInExtBlk = 0;
            this.posInDataBlk = 0;
        }

        public override void Flush()
        {
            throw new NotImplementedException();
        }

        public override int Read(byte[] buffer, int offset, int count)
        {
            if (offset != 0)
            {
                throw new ArgumentException("Only offset 0 is supported", nameof(offset));
            }
            return AdfReadFile(count, buffer).GetAwaiter().GetResult();
        }

        public override async Task<int> ReadAsync(byte[] buffer, int offset, int count, CancellationToken cancellationToken)
        {
            if (offset != 0)
            {
                throw new ArgumentException("Only offset 0 is supported", nameof(offset));
            }
            return await AdfReadFile(count, buffer);
        }

        public override long Seek(long offset, SeekOrigin origin)
        {
            throw new NotImplementedException();
        }

        public override void SetLength(long value)
        {
            throw new IOException("Set length not supported for entries. Use write buffer instead with buffer set to length");
        }

        public override void Write(byte[] buffer, int offset, int count)
        {
            throw new NotImplementedException();
        }

        public override bool CanRead => true;
        public override bool CanSeek => true;
        public override bool CanWrite { get; }
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
                currentData = await File.AdfReadDataBlock(volume, fileHdr.DataBlocks[Constants.MAX_DATABLK - 1 - curDataPtr]);
                // adfReadDataBlock(file->volume,
                //     file->fileHdr->dataBlocks[MAX_DATABLK-1-file->curDataPtr],
                //     file->currentData);
            }
            else
            {
                var nSect = fileHdr.Extension;
                i = 0;
                while(i < extBlock && nSect != 0)
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
        private int Pos2DataBlock(int position)//, int *posInExtBlk, int *posInDataBlk, int32_t *curDataN )
        {
            posInDataBlk = (uint)(position % volume.BlockSize);
            curDataPtr = (uint)(position / volume.BlockSize);
            if (posInDataBlk==0)
                curDataPtr++;
            if (curDataPtr < 72) {
                posInExtBlk = 0;
                return -1;
            }

            posInExtBlk = (uint)((position - 72 * volume.BlockSize) % volume.BlockSize);
            var extBlock = (int)((position - 72 * volume.BlockSize) / volume.BlockSize);
            if (posInExtBlk==0)
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
                throw new ArgumentOutOfRangeException(nameof(n), $"Count '{n}' is larger than buffer size '{buffer.Length}'");
            }
            
            if (n == 0)
                return n;
            var blockSize = volume.DataBlockSize;
/*puts("adfReadFile");*/
            if (pos + n > fileHdr.byteSize)
                n = (int)(fileHdr.byteSize - pos);


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
            eof = pos == fileHdr.byteSize;
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
                nSect = fileHdr.firstData;
            }
            else if (Macro.isOFS(volume.DosType))
            {
                nSect = data.NextData;
            }
            else
            {
                if (nDataBlock < Constants.MAX_DATABLK)
                    nSect = fileHdr.DataBlocks[Constants.MAX_DATABLK - 1 - nDataBlock];
                else {
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
    }
}