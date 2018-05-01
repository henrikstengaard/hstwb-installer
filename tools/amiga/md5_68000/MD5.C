#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <string.h>

#include "md52.h"
 
#define BUFFER_SIZE	4096

static const char __version[] = "$VER: MD5 1.00 (2018.05.01)"; 

void printhash (unsigned char buf[16])
{
	int i;
	printf("%02x", *buf++);
	for (i = 0; i < 15; i++)
		printf("%02x", *buf++);
	putchar('\n');
}
 
int main(int argc, char** argv)
{
	FILE* pFile;
	unsigned char data[BUFFER_SIZE], digest[16];
	int s;
	struct MD5Context ctx;

	// fail, if argument count is less than 2
	if(argc < 2)
	{
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
	memset(data, 0, BUFFER_SIZE);

	// initialize md5 context
	MD5Init2(&ctx);

	// read and update md5 context in chunks of buffer size
	do
	{
		s = fread(data,1,sizeof(data),pFile);
		MD5Update2(&ctx, data, s);
	} while (s == BUFFER_SIZE);

	// close file
	fclose(pFile);

	// finalize md5 context and print hash
	MD5Final2(digest, &ctx);
	printhash(digest);

	return 0;
}