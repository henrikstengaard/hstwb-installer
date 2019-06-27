// Free
// ----
// Author: Henrik Noerfjand Stengaard
// Date: 2019-06-21
//
// Free is a tool to returns a device's free space in mega bytes.

#include <dos/dos.h>
#include <stdio.h>
#include <math.h>

#include <clib/dos_protos.h>

int main(int argc, char *argv[]);

struct InfoData *infodata_p;
struct InfoData infodata;
BPTR lock_p;

static const char __version[] = "$VER: Free 1.00 Henrik Noerfjand Stengaard (21/06/19)";

int main(int argc, char *argv[])
{
        double megaBytesPerBlock;
        LONG freeMegaBytes;

        if(argc != 2)
        {
                printf("Free v1.0 returns a device's free space in mega bytes\n");
                printf("Usage: %s [DEVICE]\n", argv[0]);
                return 20;
        }

        lock_p = Lock(argv[1], ACCESS_READ);
        if(lock_p == NULL)
        {
                printf("ERROR: Failed to read free space from device %s\n", argv[1]);
                return 20;
        }

        infodata_p = &infodata;
        if(!Info(lock_p, infodata_p))
        {
                printf("ERROR: Failed to read free space from device %s\n", argv[1]);
                return 20;
        }
        UnLock(lock_p);

        megaBytesPerBlock = infodata_p->id_BytesPerBlock / 1048576.0;
        freeMegaBytes = floor((infodata_p->id_NumBlocks - infodata_p->id_NumBlocksUsed) * megaBytesPerBlock);

        printf("%d\n", freeMegaBytes);
        return 0;
}