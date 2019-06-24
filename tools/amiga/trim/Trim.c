// Trim
// ----
// Author: Henrik Noerfjand Stengaard
// Date: 2019-06-24
//
// Trim is a tool to trim leading and tailing whitespaces from text.

#include <stdio.h>
#include <string.h>


char* rtrim();
char* ltrim();
char* trim();
int main(int argc, char *argv[]);

static const char __version[] = "$VER: Trim 1.00 Henrik Noerfjand Stengaard (24/06/19)";

char* rtrim(char a[1024])
{
        int i=strlen(a)-1;
        for (i; a[i]==' ' || a[i]=='\t'; i--)
        {
                a[i]='\0';
        }
        return a;
}

char* ltrim(char b[1024])
{
        int i=0, j=0;
        char ltrim[1024];

        for(i; b[i]==' ' || b[i]=='\t'; i++);

        while (b[i]!='\0')
        {
                ltrim[j]=b[i];
                i++;
                j++;
        }
        ltrim[j]='\0';

        strcpy(b,ltrim);

        return b;
}

char* trim(char c[1024])
{
        rtrim(c);
        ltrim(c);
        return c;
}

int main(int argc, char *argv[])
{
        if(argc != 2)
        {
                printf("Trim v1.0 trims leading and tailing whitespaces from text\n");
                printf("Usage: %s \"[TEXT]\"\n", argv[0]);
                return 20;
        }

        printf("%s\n", trim(argv[1]));
        return 0;
}