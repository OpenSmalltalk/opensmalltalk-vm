#include <fcntl.h>
#include <sys/mman.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#define FILE_MODE   (S_IRUSR | S_IWUSR | S_IRGRP | S_IROTH)
int main(int argc, char *argv[])
{
    	int         fdin, fdout;
    	unsigned char        *src, *dst;
    	struct stat statbuf;
    	int 	i,j,size,offset,pos;
    	if (argc != 4)
	  	{
        	printf("usage: %s <fromfile> <tofile> <offset>\n", argv[0]);
			exit(1);	  
		}

    	if ((fdin = open(argv[1], O_RDONLY)) < 0)
		{
        	printf("can't open %s for reading", argv[1]);
			exit(1);
		}

    	if ((fdout = open(argv[2], O_RDWR | O_CREAT,
      	FILE_MODE)) < 0)
		{
        	printf("can't creat %s for writing", argv[2]);
			exit(1);
		}

    	if (fstat(fdin, &statbuf) < 0)   /* need size of input file */
		{
        	printf("fstat error");
			exit(1);		
		}
	offset=strtoul(argv[3],NULL,0);
	if(offset %512)
	{
	   	printf("offset not a multiple of 512 bytes\n");
	   	exit(1);
	}
    	size=((statbuf.st_size+offset+511)/512)*528;
    /* set size of output file */
    	if (lseek(fdout, size - 1, SEEK_SET) == -1)
      		{
		  	printf("lseek error");
			exit(1);
		}
    	if (write(fdout, "", 1) != 1)
		{
        	printf("write error");
			exit(1);
		}
    	if ((src = mmap(0, statbuf.st_size, PROT_READ, MAP_SHARED,
      	fdin, 0)) == MAP_FAILED)
		{
        	printf("mmap error for input");
			exit(1);
		}

    	if ((dst = mmap(0, size, PROT_READ | PROT_WRITE,
      	MAP_SHARED, fdout, 0)) == MAP_FAILED)
      		{
        	printf("mmap error for output");
			exit(1);
		}
    	//memset(dst+offset,0xFF,size-offset);
	//printf("%x\n",offset);
    	for(i=0,pos=(offset*528/512);i<statbuf.st_size;i++,pos++)
   	{
    		if((i%512)==0&&i) 
    		        for(j=0;j<16;j++)
			{
				*(dst+pos)=0xFF;
				pos++;		
			}
    		*(dst+pos)=*(src+i);
   	 }
    	msync(dst,size,MS_SYNC);
    	printf("finish\n");
    	exit(0);
}
