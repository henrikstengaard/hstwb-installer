/* Rom Md5
 * -------
 * Date: 2021-10-14
 * Author: Henrik Noerfjand Stengaard
 *
 * An Amiga CLI tool to calculate MD5 checksum of Kickstart rom file.
 * If Kickstart rom is encrypted (Cloanto Amiga Forever), rom.key file is read and
 * used to decrypt Kickstart rom before calculating MD5 checksum.
 * 
 * Returns error codes:
 * 0: OK, Kickstart rom is encrypted and rom.key was read and used to decrypt Kickstart rom.
 * 5: WARN, Kickstart rom is not encrypted.
 * 10: ERROR, Kickstart rom is encrypted, but rom.key file was not found.
 */

#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <string.h>

#include "md52.h"
 
#define BUFFER_SIZE	4096

static const char __version[] = "$VER: ROMMD5 1.00 (2021.10.14) Henrik Noerfjand Stengaard"; 

void printhash (unsigned char buf[16])
{
	int i;
	printf("%02x", *buf++);
	for (i = 0; i < 15; i++)
    {
		printf("%02x", *buf++);
    }
	putchar('\n');
}

char *basename(char *path)
{
    char *base = strrchr(path, '/');
    return base ? base+1 : path;
}

void dirname(char *path, char* dirname)
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

int readKeyFile(char *path, unsigned char** key)
{
    FILE* keyFile;
	int keyLength;

    // open file for binary read
    keyFile = fopen(path, "rb");

    // fail, if open file fails
    if (keyFile == NULL)
    {
        return 0;
    }

    // seek end of key file
    if (fseek(keyFile, 0, SEEK_END) != 0)
    {
        fclose(keyFile);
        return 0;
    }

    // get key file position as key length
    keyLength = ftell(keyFile);

    if (keyLength == 0)
    {
        fclose(keyFile);
        return 0;
    }

    // allocate key memory
    if ((*key = (unsigned char*)malloc(keyLength)) == NULL)
    {
        fclose(keyFile);
        return 0;
    }

    // initialize key memory
    memset(*key, 0, keyLength);

    // seek start of key file
    if (fseek(keyFile, 0, SEEK_SET) != 0)
    {
        fclose(keyFile);
        return 0;
    }            

    // read key
    if (fread(*key, 1, keyLength, keyFile) != keyLength)
    {
        fclose(keyFile);
        return 0;
    }

    // close file
    fclose(keyFile);

    return keyLength;
}

int main(int argc, char** argv)
{
	FILE* pFile;
	unsigned char buffer[BUFFER_SIZE], digest[16];
    unsigned char *key = NULL;
    char dirName[255] = "";
    char keyPath[255] = "";
    char encryptedRom;
    char hasReadKey;
	int i, j, bytesRead, keyLength;
	struct MD5Context ctx;
    const char magicBytes[] = "AMIROMTYPE1";

	// fail, if argument count is less than 2
	if(argc < 2)
	{
        fprintf(stderr, "ROM MD5 calculates MD5 checksum of Kickstart rom file, encrypted roms are first decrypted using rom.key.\n"); 
        fprintf(stderr, "USAGE: %s <path>\n", argv[0] ? argv[0] : "");
		return(20);
	}

	// open file for binary read
	pFile = fopen(argv[1], "rb");

	// fail, if open file fails
	if (pFile == NULL)
	{
		fputs ("File error\n",stderr);
		return(20);
	}

	// initialize buffer
	memset(buffer, 0, BUFFER_SIZE);

    // read first 11 bytes from file to compare against encrypted rom magic bytes
	bytesRead = fread(buffer, 1, 11, pFile);

    // verify first 11 bytes matches encrypted rom magic bytes
    encryptedRom = 0;
    if (bytesRead == 11)
    {
        encryptedRom = 1;
        for (i = 0; i < 11; i++)
        {
            if (magicBytes[i] != buffer[i])
            {
                encryptedRom = 0;
                break;
            }
        }
    }

	// initialize md5 context
	MD5Init2(&ctx);

    // read key file, if rom is encrypted
    hasReadKey = 0;
    if (encryptedRom)
    {
        // key path
        dirname(argv[1], dirName);
        i = strlen(dirName);
        if (i > 0)
        {
            strcat(keyPath, dirName);
            if (dirName[i - 1] != ':')
            {
                strcat(keyPath, "/");
            }
        }
        strcat(keyPath, "rom.key");

        // read key
        keyLength = readKeyFile(keyPath, &key);
        if (keyLength > 0)
        {
            hasReadKey = 1;
        }
    }

    // file is not encrypted or key file is not read, calculate md5 from buffer
    if (encryptedRom == 0 || hasReadKey == 0)
    {
        // update md5 context from buffer
        MD5Update2(&ctx, buffer, bytesRead); 
    }

	// read and update md5 context in chunks of buffer size
    j = 0;
	do
	{
        // read data into buffer
		bytesRead = fread(buffer, 1, BUFFER_SIZE, pFile);

        // decrypt data, if rom is encrypted
        if (encryptedRom == 1 && hasReadKey == 1)
        {
            for (i = 0; i < bytesRead; i++, j = (j + 1) % keyLength)
            {
                buffer[i] ^= key[j];
            }
        }

        // update md5 context from buffer
		MD5Update2(&ctx, buffer, bytesRead);
	} while (bytesRead == BUFFER_SIZE);

	// close file
	fclose(pFile);

	// finalize md5 context and print hash
	MD5Final2(digest, &ctx);
	printhash(digest);

    // warn (code 5), if rom is not encrypted
    if (encryptedRom == 0)
    {
        return 5;
    }

    // return ok (code 0), if has read key. otherwise return error (code 10, non-critical)
	return hasReadKey == 1 ? 0 : 10;
}