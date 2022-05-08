namespace HstWbInstaller.Core.IO.FastFileSystem
{
    using System;
    using System.Collections.Generic;
    using System.IO;
    using System.Linq;
    using System.Threading.Tasks;

    public static class Bitmap
    {
        
/*
 * adfReadBitmap
 *
 */
public static async Task AdfReadBitmap(Volume vol, int nBlock, RootBlock root)
{
	// int32_t mapSize, nSect;
	// int32_t j, i;
	// struct bBitmapExtBlock bmExt;
    var i = 0;
    var j = 0;

    var mapSize = nBlock / (127 * 32);
    if (nBlock % (127 * 32) != 0)
        mapSize++;
    vol.BitmapSize = mapSize;

  //   vol->bitmapTable = (struct bBitmapBlock**) malloc(sizeof(struct bBitmapBlock*)*mapSize);
  //   if (!vol->bitmapTable) { 
		// (*adfEnv.eFct)("adfReadBitmap : malloc, vol->bitmapTable");
  //       return RC_MALLOC;
  //   }
  vol.BitmapTable = new BitmapBlock[mapSize];
	// vol->bitmapBlocks = (SECTNUM*) malloc(sizeof(SECTNUM)*mapSize);
 //    if (!vol->bitmapBlocks) {
 //        free(vol->bitmapTable);
	// 	(*adfEnv.eFct)("adfReadBitmap : malloc, vol->bitmapBlocks");
 //        return RC_MALLOC;
 //    }
    vol.BitmapBlocks = new int[mapSize];
	// vol->bitmapBlocksChg = (BOOL*) malloc(sizeof(BOOL)*mapSize);
 //    if (!vol->bitmapBlocksChg) { 
 //        free(vol->bitmapTable); free(vol->bitmapBlocks);
	// 	(*adfEnv.eFct)("adfReadBitmap : malloc, vol->bitmapBlocks");
 //        return RC_MALLOC;
 //    }
 vol.BitmapBlocksChg = new bool[mapSize];
 
    for(i = 0; i < mapSize; i++)
    {
        vol.BitmapBlocksChg[i] = false;
        vol.BitmapTable[i] = new BitmapBlock(); 
		// vol->bitmapTable[i] = (struct bBitmapBlock*)malloc(sizeof(struct bBitmapBlock));
		// if (!vol->bitmapTable[i]) {
  //           free(vol->bitmapBlocksChg); free(vol->bitmapBlocks);
  //           for(j=0; j<i; j++) 
  //               free(vol->bitmapTable[j]);
  //           free(vol->bitmapTable);
	 //        (*adfEnv.eFct)("adfReadBitmap : malloc, vol->bitmapBlocks");
  //           return RC_MALLOC;
  //       }
    }

    j = 0;
    i = 0;
    var nSect = 0;
    /* bitmap pointers in rootblock : 0 <= i <BM_SIZE */
	while(i < Constants.BM_SIZE && root.bmPages[i] != 0) 
    {
		vol.BitmapBlocks[j] = nSect = root.bmPages[i];
        if (!Disk.IsSectNumValid(vol,nSect))
        {
			throw new IOException("adfReadBitmap : sector out of range");
        }

        vol.BitmapTable[j] = await AdfReadBitmapBlock(vol, nSect);
		j++; i++;
	}
	// nSect = root->bmExt;
    nSect = (int)root.BitmapExtensionBlocksOffset;
	while(nSect != 0)
    {
        /* bitmap pointers in bitmapExtBlock, j <= mapSize */
        var bmExt = await AdfReadBitmapExtBlock(vol, nSect);
		i = 0;
		while(i < 127 && j < mapSize)
        {
            nSect = bmExt.bmPages[i];
            if (!Disk.IsSectNumValid(vol, nSect))
            {
                throw new IOException("adfReadBitmap : sector out of range");
            }
			vol.BitmapBlocks[j] = nSect;

            vol.BitmapTable[j] = await AdfReadBitmapBlock(vol, nSect);
			i++; j++;
		}
		nSect = (int)bmExt.NextBitmapExtensionBlockPointer;
	}

    // return RC_OK;
}
        
/*
 * adfWriteBitmapBlock
 *
 * OK
 */
        public static async Task AdfWriteBitmapBlock(Volume vol, int nSect, BitmapBlock bitm)
        {
            // uint8_t buf[LOGICAL_BLOCK_SIZE];
            // uint32_t newSum;
	
//             memcpy(buf,bitm,LOGICAL_BLOCK_SIZE);
// #ifdef LITT_ENDIAN
//             /* little to big */
//             swapEndian(buf, SWBL_BITMAP);
// #endif
//
//             newSum = adfNormalSum(buf, 0, LOGICAL_BLOCK_SIZE);
//             swLong(buf,newSum);

/*	dumpBlock((uint8_t*)buf);*/
            var buf = await BitmapBlockWriter.BuildBlock(bitm);
            await Disk.AdfWriteBlock(vol, nSect, buf);
        }
/*
 * adfUpdateBitmap
 *
 */
        public static async Task AdfUpdateBitmap(Volume vol)
        {
            // int i;
            // struct bRootBlock root;

/*printf("adfUpdateBitmap\n");*/

            var root = await Raw.AdfReadRootBlock(vol, (int)vol.RootBlock.Offset);

            root.BitmapFlags = Constants.BM_INVALID;
            await Raw.AdfWriteRootBlock(vol, (int)vol.RootBlock.Offset, root);

            for(var i = 0; i < vol.BitmapSize; i++)
                if (vol.BitmapBlocksChg[i])
                {
                    await AdfWriteBitmapBlock(vol, vol.BitmapBlocks[i], vol.BitmapTable[i]);
                    vol.BitmapBlocksChg[i] = false;
                }

            root.BitmapFlags = Constants.BM_VALID;
            root.RootAlterationDate = DateTime.Now;
            // adfTime2AmigaTime(adfGiveCurrentTime(),&(root.days),&(root.mins),&(root.ticks));
            await Raw.AdfWriteRootBlock(vol, (int)vol.RootBlock.Offset, root);
        }
        
/*
 * adfGet1FreeBlock
 *
 */
        public static int AdfGet1FreeBlock(Volume vol)
        {
            var block = AdfGetFreeBlocks(vol,1);
            return block.Any() ? block[0] : -1;
        }        
        
        /*
 * adfGetFreeBlocks
 *
 */
        public static int[] AdfGetFreeBlocks(Volume vol, int nbSect)
        {
            var sectList = new List<int>();
            // int i, j;
            // BOOL diskFull;
            var block = (int)vol.RootBlock.Offset;

            var i = 0;
            var diskFull = false;
/*printf("lastblock=%ld\n",vol->lastBlock);*/
            while(i < nbSect && !diskFull)
            {
                if (AdfIsBlockFree(vol, block) ) {
                    sectList.Add(block);
                    i++;
                }
/*        if ( block==vol->lastBlock )
            block = vol->firstBlock+2;*/
                if ( (block + vol.FirstBlock) == vol.LastBlock)
                    block = 2;
                else if (block == vol.RootBlock.Offset-1)
                    diskFull = true;
                else
                    block++;
            }

            if (!diskFull)
                for(var j=0; j<nbSect; j++)
                    AdfSetBlockUsed( vol, sectList[j] );

            return i == nbSect ? sectList.ToArray() : Array.Empty<int>();
        }
        
        
        private static readonly uint[] bitMask = { 
            0x1, 0x2, 0x4, 0x8,
            0x10, 0x20, 0x40, 0x80,
            0x100, 0x200, 0x400, 0x800,
            0x1000, 0x2000, 0x4000, 0x8000,
            0x10000, 0x20000, 0x40000, 0x80000,
            0x100000, 0x200000, 0x400000, 0x800000,
            0x1000000, 0x2000000, 0x4000000, 0x8000000,
            0x10000000, 0x20000000, 0x40000000, 0x80000000 };
/*
 * adfSetBlockUsed
 *
 */
        public static void AdfSetBlockUsed(Volume vol, int nSect)
        {
            int sectOfMap = nSect-2;
            int block = sectOfMap/(127*32);
            int indexInMap = (sectOfMap/32)%127;

            var oldValue = vol.BitmapTable[ block ].Map[ indexInMap ];

            vol.BitmapTable[ block ].Map[ indexInMap ] = oldValue & ~bitMask[sectOfMap % 32];
            vol.BitmapBlocksChg[ block ] = true;
        }
        
/*
 * adfIsBlockFree
 *
 */
        public static bool AdfIsBlockFree(Volume vol, int nSect)
        {
            // https://github.com/lclevy/ADFlib/blob/be8a6f6e8d0ca8fda963803eef77366c7584649a/src/adf_bitm.c#L185
            
            int sectOfMap = nSect-2;
            int block = sectOfMap / (127 * 32);
            int indexInMap = (sectOfMap / 32) % 127;
	
/*printf("sect=%d block=%d ind=%d,  ",sectOfMap,block,indexInMap);
printf("bit=%d,  ",sectOfMap%32);
printf("bitm=%x,  ",bitMask[ sectOfMap%32]);
printf("res=%x,  ",vol->bitmapTable[ block ]->map[ indexInMap ]
        & bitMask[ sectOfMap%32 ]);
*/
            return (vol.BitmapTable[block].Map[ indexInMap ] & bitMask[ sectOfMap % 32 ])!=0;
        }
        
/*
 * adfReadBitmapBlock
 *
 * ENDIAN DEPENDENT
 */
        public static async Task<BitmapBlock> AdfReadBitmapBlock(Volume vol, int nSect)
        {
            // uint8_t buf[LOGICAL_BLOCK_SIZE];

/*printf("bitmap %ld\n",nSect);*/
            var buf = await Disk.AdfReadBlock(vol, nSect);
//                 return RC_ERROR;
//
//             memcpy(bitm, buf, LOGICAL_BLOCK_SIZE);
// #ifdef LITT_ENDIAN
//             /* big to little = 68000 to x86 */
//             swapEndian((uint8_t*)bitm, SWBL_BITMAP);
// #endif
            var bitm = await BitmapBlockReader.Parse(buf);

            if (bitm.Checksum != Raw.AdfNormalSum(buf, 0, buf.Length))
            {
                throw new IOException("adfReadBitmapBlock : invalid checksum");
            }
            //
            // return RC_OK;
            return bitm;
        }
        
/*
 * adfReadBitmapExtBlock
 *
 * ENDIAN DEPENDENT
 */
        public static async Task<BitmapExtensionBlock> AdfReadBitmapExtBlock(Volume vol, int nSect)
        {
            // uint8_t buf[LOGICAL_BLOCK_SIZE];

            var buf = await Disk.AdfReadBlock(vol, nSect);
//                 return RC_ERROR;
//
//             memcpy(bitme, buf, LOGICAL_BLOCK_SIZE);
// #ifdef LITT_ENDIAN
//             swapEndian((uint8_t*)bitme, SWBL_BITMAP);
// #endif

            return await BitmapExtensionBlockReader.Parse(buf);
        }        
    }
}