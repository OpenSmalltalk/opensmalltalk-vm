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
  int i;
  int pos;  /* position in the header while writing arguments */

  /* imported from sqXWindow.c */
  extern int    vmArgCnt;
  extern char **vmArgVec;

  extern int    squeakArgCnt;
  extern char **squeakArgVec;
  

  memset(header, 0, HEADER_SIZE);
  
  /* print the VM name and a special argument to the first line of the
     header */
  if(strlen(VM_NAME) + strlen("-args_in_header") + 5 > HEADER_SIZE) {
    /* not enough space -- give up and write an empty header */
    return;
  }
  
  sprintf(header, "#!%s -args_in_header\n", VM_NAME);

  /** try to print the arguments out **/

  /* print VM args */
  pos = strlen(header);
  for(i=1; i<vmArgCnt; i++) {  /* start at 1 to skip the VM name */
    char *arg = vmArgVec[i];
    
    if(strcmp(arg, "-args_in_header") == 0)
      continue;  /* don't save the -args_in_header argument */

    if(pos + strlen(arg) + 2 > HEADER_SIZE)
      /* out of space -- give up on the header */
      goto give_up;

    strcpy(header+pos, arg);
    pos += strlen(arg) + 1;
  }

#if 0  /* should Squeak arguments be saved?  I don't really think so:
	  the purpose of saving arguments is IMHO to help recreate the
	  exact state of the image when it is restarted.  Most VM
	  arguments will be necessary to do this.  Most image
	  arguments, on the other hand, will get their effect saved
	  simply because all the objects are saved in the snapshot.
	  -Lex */


  /* put a "--" between VM and Squeak args, just to be sure */
  if(pos + 4 > HEADER_SIZE)
    goto give_up;
  strcpy(header+pos, "--");
  pos += 3;
  

  /* print out Squeak args */
  for(i=0; i<squeakArgCnt; i++) {
    char *arg = squeakArgVec[i];
    
    if(pos + strlen(arg) + 2 > HEADER_SIZE)
      /* out of space -- give up on the header */
      goto give_up;

    strcpy(header+pos, arg);
    pos += strlen(arg) + 1;
  }
#endif

  /* all done */
  return;

  
give_up:  /* space ran out; give up and use an all-0's header.
             Conceivably, this could switch to some other mode, where
             the arguments are stored *after* the image data  */
  memset(header, 0, HEADER_SIZE);
  return;
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

