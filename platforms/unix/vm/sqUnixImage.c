/* sqUnixImage.c -- routines for reading and writing images */


#include "sq.h"
#include <string.h>
#include <assert.h>
#include <fcntl.h>

/* the standard header size; no more, no less! */
#define HEADER_SIZE 512


/* writeImageHeader(file), defined below.  Write a Unixy header to an
   image file */
static int writeImageHeader(sqImageFile file);



/* open a file for writing an image.  Try to write a Unixy header to it */
sqImageFile sqImageFileOpen(const char *fileName, const char *mode)
{
  int fd;
  sqImageFile file;

  /* this routine is only used for *writing* files! */
  assert(strchr(mode, 'w'));

  
  /* open the file */
  unlink(fileName);  /* unlink, so that (a) if the new file is
                        shorter, it's really shorter, and (b), so that
                        the mode is set properly.  As scary as it
                        looks, this isn't really much more dangerous
                        that the in-place overwrites */
  fd = open(fileName, O_WRONLY|O_CREAT, 0777);
  if(fd < 0) {
    perror(fileName);
    return NULL;
  }
  

  /* convert to an ANSI file */
  file = fdopen(fd, mode);
  if(file == NULL) {
    perror("fdopen");
    close(fd);
    return NULL;
  }
  

  /* add a header */
  if(writeImageHeader(file)) {
      /* error writing the header! */
      fclose(file);
      return NULL;
  }

  return file;
}



/* where to start putting the real image data; skip 512 bytes -- a
   magic offset that the image file reader  will try automatically */
int sqImageFileStartLocation(sqImageFile file, const char *fileName, int size) 
{
  return HEADER_SIZE;
}


/* put together a header to be written to the image file */
static void assembleHeader(char *header)
{
  memset(header, 0, HEADER_SIZE);
  
  /* check that there is room for the VM */
  if(strlen(VM_NAME) + 3 > HEADER_SIZE) {
    /* no space -- write an empty header */
    return;
  }
  

  /* plenty of space -- print the VM name to the header */
  sprintf(header, "#!%s\n", VM_NAME);
}


/* write a Unixy header to the image file */ 
static int writeImageHeader(sqImageFile file) 
{
  char header[HEADER_SIZE];

  assembleHeader(header);

  if(fwrite(header, sizeof(header), 1, file) < 1)
    return -1;

  return 0;
}

