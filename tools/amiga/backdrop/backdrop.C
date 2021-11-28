/* CD into program's own directory on Kickstart 1.3.
   Link with minimal C-startup. */
// http://eab.abime.net/showthread.php?t=72464&page=2
#include <string.h>
#include <dos/dosextens.h> // openlibrary
#include <workbench/startup.h>
#include <proto/exec.h>
#include <proto/dos.h> // Lock, ParentDir, ...
#include <stdio.h>
//#include <dos/dos.h>
//#include <clib/dos_protos.h>

void devicename(char *path, char* dirname)
{
    char *base = strrchr(path, '/');
    if (base)
    {
        strncpy(dirname, path, base-path);
        dirname[base-path+1] = '\0';
        return;
    }

    base = strrchr(path, ':');
    if (base)
    {
        strncpy(dirname, path, base-path+1);
        dirname[base-path+2] = '\0';
        return;
    }

    dirname[0] = '\0';
} 

typedef void* PTR;
//struct DosLibrary* DOSBaseX;

int main(int argc, char** argv)
{
    BPTR progdir, prevdir;
    BPTR prglock;
    BPTR	mydir, curdir;
    unsigned char* p;
    char cmd[200];
    int i;





    DOSBase = (PTR)OpenLibrary("dos.library", 33);

    printf("file '%s'\n", argv[1]);



    // unsigned char* p;
    // BPTR prglock;

    // /* Copy the command name BCPL string to a C-style string. */

    // char cmd[200];
    // p = (PTR)(cli->cli_CommandName*4);
    // memcpy(cmd, p+1, p[0]);
    // cmd[p[0]] = 0;

    /* Lock on the command name and get its parent, which will be the program
       dir. This works because Lock() accepts relative paths. */

    prglock = Lock(argv[1], SHARED_LOCK);
    progdir = ParentDir(prglock);
    UnLock(prglock);

    prevdir = CurrentDir(progdir);
    CurrentDir(prevdir);

    UnLock(progdir);
    CloseLibrary((PTR)DOSBase);

    p = (unsigned char *) BADDR(progdir);
    //p = (PTR)(progdir*4);
    memcpy(cmd, p+1, (unsigned char)p);
    cmd[(unsigned char)p] = 0;

    for (i = 0; i < 10; i++)
    {
    printf("%02x", (unsigned char)p[i]);

    }

    printf("\nprogdir '%s', %d\n", cmd, (unsigned char)p[0]);

    p = (PTR)(prevdir*4);
    memcpy(cmd, p+1, (unsigned char)p);
    cmd[(unsigned char)p] = 0;
    printf("prevdir '%s', %d\n", cmd, (unsigned char)p[0]);
// mydir = Lock(argv[1], (long)ACCESS_READ);  

//     curdir = CurrentDir(mydir);
//     p = (PTR)curdir;
//     memcpy(cmd, p+1, p[0]);
//     cmd[p[0]] = 0;
//     printf("curdir '%s'\n", cmd);
//     //printf("curdir '%b'\n", curdir);
// 	UnLock(curdir);
// 	UnLock(mydir);

    //prglock = Lock(argv[1], ACCESS_READ);
    //progdir = ParentDir(prglock);
    //prevdir = CurrentDir(prglock);
    //UnLock(prglock);
/*
    p = (PTR)progdir;
    memcpy(cmd, p+1, p[0]);
    cmd[p[0]] = 0;
    printf("progdir '%s'\n", cmd);

    p = (PTR)prevdir;
    memcpy(cmd, p+1, p[0]);
    cmd[p[0]] = 0;
    printf("prevdir '%s'\n", cmd);

    UnLock(prglock);
*/
    //CloseLibrary((PTR)DOSBase);
}