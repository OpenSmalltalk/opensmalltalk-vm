/* sqUnixFile.c -- directory operations for Unix
 * 
 *   Copyright (C) 1996-2004 by Ian Piumarta and other authors/contributors
 *                              listed elsewhere in this file.
 *   All rights reserved.
 *   
 *   This file is part of Unix Squeak.
 * 
 *      You are NOT ALLOWED to distribute modified versions of this file
 *      under its original name.  If you modify this file then you MUST
 *      rename it before making your modifications available publicly.
 * 
 *   This file is distributed in the hope that it will be useful, but WITHOUT
 *   ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 *   FITNESS FOR A PARTICULAR PURPOSE.
 *   
 *   You may use and/or distribute this file ONLY as part of Squeak, under
 *   the terms of the Squeak License as described in `LICENSE' in the base of
 *   this distribution, subject to the following additional restrictions:
 * 
 *   1. The origin of this software must not be misrepresented; you must not
 *      claim that you wrote the original software.  If you use this software
 *      in a product, an acknowledgment to the original author(s) (and any
 *      other contributors mentioned herein) in the product documentation
 *      would be appreciated but is not required.
 * 
 *   2. You must not distribute (or make publicly available by any
 *      means) a modified copy of this file unless you first rename it.
 * 
 *   3. This notice must not be removed or altered in any source distribution.
 * 
 *   Using (or modifying this file for use) in any context other than Squeak
 *   changes these copyright conditions.  Read the file `COPYING' in the
 *   directory `platforms/unix/doc' before proceeding with any such use.
 */

/* Author: Ian.Piumarta@INRIA.Fr
 * 
 * Last edited: 2004-06-13 19:42:03 by piumarta on emilia.local
 */

#include "sq.h"
#include "FilePlugin.h"
#include "sqUnixCharConv.h"

#ifdef HAVE_DIRENT_H
# include <dirent.h>
# define NAMLEN(dirent) strlen((dirent)->d_name)
#else
# define dirent direct
# define NAMLEN(dirent) (dirent)->d_namlen
# ifdef HAVE_SYS_NDIR_H
#  include <sys/ndir.h>
# endif
# ifdef HAVE_SYS_DIR_H
#  include <sys/dir.h>
# endif
# ifdef HAVE_NDIR_H
#  include <ndir.h>
# endif
#endif

#ifdef HAVE_UNISTD_H
# include <sys/types.h>
# include <unistd.h>
#endif

#include <time.h>
#include <errno.h>
#include <string.h>
#include <sys/param.h>
#include <sys/stat.h>

/***
	The interface to the directory primitive is path based.
	That is, the client supplies a Squeak string describing
	the path to the directory on every call. To avoid traversing
	this path on every call, a cache is maintained of the last
	path seen, along with the Mac volume and folder reference
	numbers corresponding to that path.
***/

/*** Constants ***/
#define ENTRY_FOUND     0
#define NO_MORE_ENTRIES 1
#define BAD_PATH        2

#define DELIMITER '/'

/*** Variables ***/
char lastPath[MAXPATHLEN+1];
int  lastPathValid = false;
int  lastIndex= -1;
DIR *openDir= 0;


/*** Functions ***/

extern time_t convertToSqueakTime(time_t unixTime);


sqInt dir_Create(char *pathString, sqInt pathStringLength)
{
  /* Create a new directory with the given path. By default, this
     directory is created relative to the cwd. */
  char name[MAXPATHLEN+1];
  int i;
  if (pathStringLength >= MAXPATHLEN)
    return false;
  if (!sq2uxPath(pathString, pathStringLength, name, MAXPATHLEN, 1))
    return false;
  return mkdir(name, 0777) == 0;	/* rwxrwxrwx & ~umask */
}


sqInt dir_Delete(char *pathString, sqInt pathStringLength)
{
  /* Delete the existing directory with the given path. */
  char name[MAXPATHLEN+1];
  int i;
  if (pathStringLength >= MAXPATHLEN)
    return false;
  if (!sq2uxPath(pathString, pathStringLength, name, MAXPATHLEN, 1))
    return false;
  return rmdir(name) == 0;
}


sqInt dir_Delimitor(void)
{
  return DELIMITER;
}


static int maybeOpenDir(char *unixPath)
{
  /* if the last opendir was to the same directory, re-use the directory
     pointer from last time.  Otherwise close the previous directory,
     open the new one, and save its name.  Return true if the operation
     was successful, false if not. */
  if (!lastPathValid || strcmp(lastPath, unixPath))
    {
      /* invalidate the old, open the new */
      if (lastPathValid)
	closedir(openDir);
      lastPathValid= false;
      strcpy(lastPath, unixPath);
      if ((openDir= opendir(unixPath)) == 0)
	return false;
      lastPathValid= true;
      lastIndex= 0;	/* first entry is index 1 */
    }
  return true;
}


sqInt dir_Lookup(char *pathString, sqInt pathStringLength, sqInt index,
/* outputs: */  char *name, sqInt *nameLength, sqInt *creationDate, sqInt *modificationDate,
		sqInt *isDirectory, squeakFileOffsetType *sizeIfFile)
{
  /* Lookup the index-th entry of the directory with the given path, starting
     at the root of the file system. Set the name, name length, creation date,
     creation time, directory flag, and file size (if the entry is a file).
     Return:	0 	if a entry is found at the given index
     		1	if the directory has fewer than index entries
		2	if the given path has bad syntax or does not reach a directory
  */

  int i;
  int nameLen= 0;
  struct dirent *dirEntry= 0;
  char unixPath[MAXPATHLEN+1];
  struct stat statBuf;

  /* default return values */
  *name             = 0;
  *nameLength       = 0;
  *creationDate     = 0;
  *modificationDate = 0;
  *isDirectory      = false;
  *sizeIfFile       = 0;

  if ((pathStringLength == 0))
    strcpy(unixPath, ".");
  else if (!sq2uxPath(pathString, pathStringLength, unixPath, MAXPATHLEN, 1))
    return BAD_PATH;

  /* get file or directory info */
  if (!maybeOpenDir(unixPath))
    return BAD_PATH;

  if (++lastIndex == index)
    index= 1;		/* fake that the dir is rewound and we want the first entry */
  else
    {
      rewinddir(openDir);	/* really rewind it, and read to the index */
      lastIndex= index;
    }

  for (i= 0; i < index; i++)
    {
    nextEntry:
      do
	{ 
	  errno= 0; 
	  dirEntry= readdir(openDir);
	}
      while ((dirEntry == 0) && (errno == EINTR));

      if (!dirEntry)
	return NO_MORE_ENTRIES;
      
      nameLen= NAMLEN(dirEntry);

      /* ignore '.' and '..' (these are not *guaranteed* to be first) */
      if (nameLen < 3 && dirEntry->d_name[0] == '.')
	if (nameLen == 1 || dirEntry->d_name[1] == '.')
	  goto nextEntry;
    }

  *nameLength= ux2sqPath(dirEntry->d_name, nameLen, name, MAXPATHLEN, 0);

  {
    char terminatedName[MAXPATHLEN];
    strncpy(terminatedName, dirEntry->d_name, nameLen);
    terminatedName[nameLen]= '\0';
    strcat(unixPath, "/");
    strcat(unixPath, terminatedName);
    if (stat(unixPath, &statBuf) && lstat(unixPath, &statBuf))
      {
	/* We can't stat the entry, but failing here would invalidate
	   the whole directory --bertf */
	return ENTRY_FOUND;
      }
  }

  /* last change time */
  *creationDate= convertToSqueakTime(statBuf.st_ctime);
  /* modification time */
  *modificationDate= convertToSqueakTime(statBuf.st_mtime);

  if (S_ISDIR(statBuf.st_mode))
    *isDirectory= true;
  else
    *sizeIfFile= statBuf.st_size;

  return ENTRY_FOUND;
}


/* unix files are untyped, and the creator is correct by default */


sqInt dir_SetMacFileTypeAndCreator(char *filename, sqInt filenameSize, char *fType, char *fCreator)
{
  return true;
}

sqInt dir_GetMacFileTypeAndCreator(char *filename, sqInt filenameSize, char *fType, char *fCreator)
{
  return true;
}
