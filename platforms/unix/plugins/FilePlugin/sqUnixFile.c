/* sqUnixFile.c -- directory operations for Unix
 * 
 *   Copyright (C) 1996 1997 1998 1999 2000 2001 Ian Piumarta and individual
 *      authors/contributors listed elsewhere in this file.
 *   All rights reserved.
 *   
 *   This file is part of Unix Squeak.
 * 
 *   This file is distributed in the hope that it will be useful, but WITHOUT
 *   ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 *   FITNESS FOR A PARTICULAR PURPOSE.
 *   
 *   You may use and/or distribute this file ONLY as part of Squeak, under
 *   the terms of the Squeak License as described in `LICENSE' in the base of
 *   this distribution, subject to the following restrictions:
 * 
 *   1. The origin of this software must not be misrepresented; you must not
 *      claim that you wrote the original software.  If you use this software
 *      in a product, an acknowledgment to the original author(s) (and any
 *      other contributors mentioned herein) in the product documentation
 *      would be appreciated but is not required.
 * 
 *   2. This notice may not be removed or altered in any source distribution.
 * 
 *   Using or modifying this file for use in any context other than Squeak
 *   changes these copyright conditions.  Read the file `COPYING' in the base
 *   of the distribution before proceeding with any such use.
 * 
 *   You are STRONGLY DISCOURAGED from distributing a modified version of
 *   this file under its original name without permission.  If you must
 *   change it, rename it first.
 */

/* Author: Ian.Piumarta@INRIA.Fr
 * 
 * Last edited: 2001-02-12 15:06:09 by piumarta on rnd10-51.rd.wdi.disney.com
 */

#include "sq.h"

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
#include <sys/param.h>
#include <sys/stat.h>
#include <errno.h>
#include <string.h>

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

int equalsLastPath(char *pathString, int pathStringLength);
int recordPath(char *pathString, int pathStringLength, int refNum, int volNum);
int maybeOpenDir(char *unixPath);

int dir_Create(char *pathString, int pathStringLength)
{
  /* Create a new directory with the given path. By default, this
     directory is created relative to the cwd. */
  char name[MAXPATHLEN+1];
  int i;
  if (!plugInAllowAccessToFilePath(pathString, pathStringLength))
    return false;
  if (pathStringLength >= MAXPATHLEN)
    return false;
  for (i = 0; i < pathStringLength; i++)
    name[i] = pathString[i];
  name[i] = 0; /* string terminator */
  return mkdir(name, 0777) == 0;	/* rwxrwxrwx & ~umask */
}

int dir_Delete(char *pathString, int pathStringLength)
{
  /* Delete the existing directory with the given path. */
  char name[MAXPATHLEN+1];
  int i;
  if (!plugInAllowAccessToFilePath(pathString, pathStringLength))
    return false;
  if (pathStringLength >= MAXPATHLEN)
    return false;
  for (i = 0; i < pathStringLength; i++)
    name[i] = pathString[i];
  name[i] = 0; /* string terminator */
  return rmdir(name) == 0;
}

int dir_Delimitor(void)
{
  return DELIMITER;
}

int dir_Lookup(char *pathString, int pathStringLength, int index,
/* outputs: */ char *name, int *nameLength, int *creationDate, int *modificationDate,
	       int *isDirectory, int *sizeIfFile)
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

  if (!plugInAllowAccessToFilePath(pathString, pathStringLength))
    return NO_MORE_ENTRIES;

  if ((pathStringLength == 0))
    strcpy(unixPath, ".");
  else
    {
      for (i= 0; i < pathStringLength; i++)
	unixPath[i]= pathString[i];
      unixPath[i]= 0;
    }

  /* get file or directory info */
  if (!maybeOpenDir(unixPath))
    {
      return BAD_PATH;
    }

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
      do { 
        errno= 0; 
      dirEntry= readdir(openDir);
      }  while(dirEntry==0 && errno==EINTR);

      if (!dirEntry)
	{
	  return NO_MORE_ENTRIES;
	}
      nameLen= NAMLEN(dirEntry);
      /* ignore '.' and '..' (these are not *guaranteed* to be first) */
      if (nameLen < 3 && dirEntry->d_name[0] == '.')
	if (nameLen == 1 || dirEntry->d_name[1] == '.')
	  goto nextEntry;
    }

  strncpy(name, dirEntry->d_name, nameLen);
  *nameLength= nameLen;

  {
    char terminatedName[MAXPATHLEN];
    strncpy(terminatedName, dirEntry->d_name, nameLen);
    terminatedName[nameLen]= '\0';
    strcat(unixPath, "/");
    strcat(unixPath, terminatedName);
    if (stat(unixPath, &statBuf) && lstat(unixPath, &statBuf))
      {
	return BAD_PATH;
      }
  }

  /* use modification time instead (just like ls) */
  *creationDate= convertToSqueakTime(statBuf.st_mtime);
  /* use status change time instead */
  *modificationDate= convertToSqueakTime(statBuf.st_ctime);

  if (S_ISDIR(statBuf.st_mode))
    *isDirectory= true;
  else
    *sizeIfFile= statBuf.st_size;

  return ENTRY_FOUND;
}

int maybeOpenDir(char *unixPath)
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

int dir_SetMacFileTypeAndCreator(char *filename, int filenameSize,
				 char *fType, char *fCreator)
{
  /* unix files are untyped, and the creator is correct by default */
  return true;
}


int dir_GetMacFileTypeAndCreator(char *filename, int filenameSize,
				 char *fType, char *fCreator)
{
  return true;
}

