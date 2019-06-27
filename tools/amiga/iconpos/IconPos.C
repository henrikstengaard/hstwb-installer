// IconPos
// -------
// Author: Henrik Noerfjand Stengaard
// Date: 2019-01-14
//
// IconPos is a tool to change icon position and drawer window position and size.
//
// Usage: IconPos <file> X <x> Y <y> DLEFT <dleft> DTOP <dtop> DWIDTH <dwidth> DHEIGHT <dheight>
//
// Reference: http://krashan.ppa.pl/articles/amigaicons/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
 
static const char __version[] = "$VER: IconPos 1.00 Henrik Noerfjand Stengaard (14.01.2019)"; 

// seek file
void seek(FILE* pFile, long offset)
{
	if (pFile == NULL)
	{
		fprintf(stderr, "File not open\n");
		exit(EXIT_FAILURE);
	}

	if (ftell(pFile) == offset)
	{
		return;
	}

	fseek(pFile, offset, SEEK_SET);

	if(ferror(pFile))
	{
		fprintf(stderr, "Unable to seek file offset %d\n", offset);
		exit(EXIT_FAILURE);
	}
}

// read int16 from file
short read_int16(FILE* pFile)
{
	short value;

	if (pFile == NULL)
	{
		fprintf(stderr, "File not open\n");
		exit(EXIT_FAILURE);
	}

	fread(&value, sizeof(short), 1, pFile);

	if(ferror(pFile))
	{
		fprintf(stderr, "Unable to read int16 from file\n");
		exit(EXIT_FAILURE);
	}

	return value;
}

// read uint16 from file
unsigned short read_uint16(FILE* pFile)
{
	unsigned short value;

	if (pFile == NULL)
	{
		fprintf(stderr, "File not open\n");
		exit(EXIT_FAILURE);
	}

	fread(&value, sizeof(unsigned short), 1, pFile);

	if(ferror(pFile))
	{
		fprintf(stderr, "Unable to read uint16 from file\n");
		exit(EXIT_FAILURE);
	}

	return value;
}

// read uint32 from file
unsigned int read_uint32(FILE* pFile)
{
	unsigned int value;

	if (pFile == NULL)
	{
		fprintf(stderr, "File not open\n");
		exit(EXIT_FAILURE);
	}

	fread(&value, sizeof(unsigned int), 1, pFile);

	if(ferror(pFile))
	{
		fprintf(stderr, "Unable to read uint32 from file\n");
		exit(EXIT_FAILURE);
	}

	return value;
}

// write int16 to file
void write_int16(FILE* pFile, short value)
{
	if (pFile == NULL)
	{
		fprintf(stderr, "File not open\n");
		exit(EXIT_FAILURE);
	}

	fwrite(&value, sizeof(short), 1, pFile);

	if(ferror(pFile))
	{
		fprintf(stderr, "Unable to write int16 to file\n");
		exit(EXIT_FAILURE);
	}
}

// write int32 to file
void write_int32(FILE* pFile, int value)
{
	if (pFile == NULL)
	{
		fprintf(stderr, "File not open\n");
		exit(EXIT_FAILURE);
	}

	fwrite(&value, sizeof(int), 1, pFile);

	if(ferror(pFile))
	{
		fprintf(stderr, "Unable to write int32 to file\n");
		exit(EXIT_FAILURE);
	}
}

int main(int argc, char** argv)
{
	FILE * pFile;
	int magic, i;
	int pCurrentX, pCurrentY, pDrawerLeft, pDrawerTop, pDrawerWidth, pDrawerHeight;
	char* pInfoFile;
	 
	// fail, if argument count is less than 2
	if(argc < 2)
	{
		fprintf(stderr, "USAGE: %s <file> X <x> Y <y> DLEFT <dleft> DTOP <dtop> DWIDTH <dwidth> DHEIGHT <dheight>\n", argv[0] ? argv[0] : "");
		return(20);
	}

	pCurrentX = NULL; // Virtual horizontal position of the icon in the drawer window.
	pCurrentY = NULL; // Virtual vertical position of the icon in the drawer window.
	pDrawerLeft = NULL; // Drawer window left edge relative to the Workbench screen.
	pDrawerTop = NULL; // Drawer window top edge relative to the Workbench screen.
	pDrawerWidth = NULL; // Drawer window width.
	pDrawerHeight = NULL; // Drawer window height.

	// parse arguments
	for(i = 0; i < argc; i++)
	{
		// parse current x, if defined
		if (strcmp(strlwr(argv[i]), "x") == 0 && i - 1 < argc)
		{
			pCurrentX = strtol(argv[i + 1], NULL, 10);
		}

		// parse current y, if defined
		if (strcmp(strlwr(argv[i]), "y") == 0 && i - 1 < argc)
		{
			pCurrentY = strtol(argv[i + 1], NULL, 10);
		}

		// parse drawer left, if defined
		if (strcmp(strlwr(argv[i]), "dleft") == 0 && i - 1 < argc)
		{
			pDrawerLeft = strtol(argv[i + 1], NULL, 10);
		}

		// parse drawer top, if defined
		if (strcmp(strlwr(argv[i]), "dtop") == 0 && i - 1 < argc)
		{
			pDrawerTop = strtol(argv[i + 1], NULL, 10);
		}

		// parse drawer width, if defined
		if (strcmp(strlwr(argv[i]), "dwidth") == 0 && i - 1 < argc)
		{
			pDrawerWidth = strtol(argv[i + 1], NULL, 10);
		}

		// parse drawer height, if defined
		if (strcmp(strlwr(argv[i]), "dheight") == 0 && i - 1 < argc)
		{
			pDrawerHeight = strtol(argv[i + 1], NULL, 10);
		}
	}

	// info file
	pInfoFile = malloc(strlen(argv[1]) + strlen(".info") + 1);

	// fail, if info file is null
	if (pInfoFile == NULL)
	{
		fprintf(stderr, "Malloc error\n");
		return(20);
	}

	pInfoFile[0] = '\0';
	strcat(pInfoFile, argv[1]);
	strcat(pInfoFile, ".info");

	// open file for binary read and write
	pFile = fopen(pInfoFile, "rb+");

	// fail, if file is not open
	if (pFile == NULL)
	{
		fprintf(stderr, "File error\n");
		return(20);
	}

	// read magic
	magic = read_uint16(pFile);

	// fail, if magic doesn't match
	if (magic != 58128)
	{
		fprintf(stderr, "Invalid icon file\n");
		fclose(pFile);
		return(20);
	}

	// write current x, if defined
	if (pCurrentX != NULL)
	{
		seek(pFile, 58);
		write_int32(pFile, pCurrentX);
	}

	// write current y, if defined
	if (pCurrentY != NULL)
	{
		seek(pFile, 62);
		write_int32(pFile, pCurrentY);
	}

	// write drawer left, if defined
	if (pDrawerLeft != NULL)
	{
		seek(pFile, 78);
		write_int16(pFile, pDrawerLeft);
	}

	// write drawer top, if defined
	if (pDrawerTop != NULL)
	{
		seek(pFile, 80);
		write_int16(pFile, pDrawerTop);
	}

	// write drawer width, if defined
	if (pDrawerWidth != NULL)
	{
		seek(pFile, 82);
		write_int16(pFile, pDrawerWidth);
	}

	// write drawer height, if defined
	if (pDrawerHeight != NULL)
	{
		seek(pFile, 84);
		write_int16(pFile, pDrawerHeight);
	}

	// close file
	fclose(pFile);

	return 0;
}