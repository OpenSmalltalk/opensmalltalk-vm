/* sqUnixFile.c -- directory operations for Unix
 * 
 *   Copyright (C) 1996-2004 by Ian Piumarta and other authors/contributors
 *                              listed elsewhere in this file.
 *   All rights reserved.
 *   
 *   This file is part of Unix Squeak.
 * 
 *   Permission is hereby granted, free of charge, to any person obtaining a
 *   copy of this software and associated documentation files (the "Software"),
 *   to deal in the Software without restriction, including without limitation
 *   the rights to use, copy, modify, merge, publish, distribute, sublicense,
 *   and/or sell copies of the Software, and to permit persons to whom the
 *   Software is furnished to do so, subject to the following conditions:
 * 
 *   The above copyright notice and this permission notice shall be included in
 *   all copies or substantial portions of the Software.
 * 
 *   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 *   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 *   FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 *   DEALINGS IN THE SOFTWARE.
 */

/* Author: Ian.Piumarta@INRIA.Fr
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

#include "pharovm/debug.h"

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


void 
sqCloseDir()
{
  /* Ensure that the cached open directory is closed */
  if (lastPathValid)
    closedir(openDir);
  lastPathValid= false;
  lastIndex= -1;
  lastPath[0]= '\0';
}



sqInt dir_Create(char *pathString, sqInt pathStringLength)
{
  /* Create a new directory with the given path. By default, this
     directory is created relative to the cwd. */
  char name[MAXPATHLEN+1];
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
  if (pathStringLength >= MAXPATHLEN)
    return false;
  if (!sq2uxPath(pathString, pathStringLength, name, MAXPATHLEN, 1))
    return false;
  if (lastPathValid && !strcmp(lastPath, name))
    sqCloseDir();
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
    strncpy(lastPath, unixPath, MAXPATHLEN);
    if ((openDir= opendir(unixPath)) == 0)
      return false;
    lastPathValid= true;
    lastIndex= 0;	/* first entry is index 1 */
  }
  return true;
}

sqInt dir_Lookup(char *pathString, sqInt pathStringLength, sqInt index,
/* outputs: */  char *name, sqInt *nameLength, sqInt *creationDate, sqInt *modificationDate,
		sqInt *isDirectory, squeakFileOffsetType *sizeIfFile, sqInt * posixPermissions, sqInt *isSymlink)
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
  *posixPermissions = 0;
  *isSymlink        = false;

  if (pathStringLength == 0)
    strcpy(unixPath, ".");
  else if (!sq2uxPath(pathString, pathStringLength, unixPath, MAXPATHLEN, 1))
    return BAD_PATH;

  /* (Re)open the directory if required */
  if (lastPathValid && 
      ++lastIndex == index &&
      !strcmp(lastPath, unixPath))
    /* We can re-use the cached open directory.
     * We want the next entry, so reset index */
    index= 1;
  else
    { /* The directory must be opened or reopened.
       * We can't just rewind the directory as entries appear to be cached on
       * CIFS mounted file systems, and files may have been deleted between 
       * calls. */
      sqCloseDir();
      if (!maybeOpenDir(unixPath))
        return BAD_PATH;
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
    char terminatedName[MAXPATHLEN+1];
    if(nameLen > MAXPATHLEN)
      return BAD_PATH;
    strncpy(terminatedName, dirEntry->d_name, nameLen);
    terminatedName[nameLen]= '\0';
    if(strlen(unixPath) + 1 + nameLen > MAXPATHLEN)
      return BAD_PATH;
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

  *isSymlink = S_ISLNK(statBuf.st_mode);
  *posixPermissions = statBuf.st_mode & 0777;

  return ENTRY_FOUND;
}


sqInt dir_EntryLookup(char *pathString, sqInt pathStringLength, char* nameString, sqInt nameStringLength,
/* outputs: */  char *name, sqInt *nameLength, sqInt *creationDate, sqInt *modificationDate,
		sqInt *isDirectory, squeakFileOffsetType *sizeIfFile, sqInt *posixPermissions, sqInt *isSymlink)
{
  /* Lookup the given name in the given directory,
     Set the name, name length, creation date,
     creation time, directory flag, and file size (if the entry is a file).
     Return:	0 	if a entry is found at the given index
     		1	if there is no such entry in the directory
		2	if the given path has bad syntax or does not reach a directory
  */
  
  char unixPath[MAXPATHLEN+1];
  struct stat statBuf;

  /* default return values */
  *name             = 0;
  *nameLength       = 0;
  *creationDate     = 0;
  *modificationDate = 0;
  *isDirectory      = false;
  *sizeIfFile       = 0;
  *posixPermissions = 0;
  *isSymlink        = false;

  if (pathStringLength == 0)
    strcpy(unixPath, ".");
  else if (!sq2uxPath(pathString, pathStringLength, unixPath, MAXPATHLEN, 1))
    return BAD_PATH;

  char terminatedName[MAXPATHLEN+1];
  if(nameStringLength > MAXPATHLEN)
    return BAD_PATH;
  strncpy(terminatedName, nameString, nameStringLength);
  terminatedName[nameStringLength]= '\0';
  if(strlen(unixPath) + 1 + nameStringLength > MAXPATHLEN)
    return BAD_PATH;
  strcat(unixPath, "/");
  strcat(unixPath, terminatedName);
  if (stat(unixPath, &statBuf) && lstat(unixPath, &statBuf)) {
	return NO_MORE_ENTRIES;
  }

  /* To match the results of dir_Lookup, copy back the file name */
  *nameLength = ux2sqPath(nameString, nameStringLength, name, 256, 0);

  /* last change time */
  *creationDate= convertToSqueakTime(statBuf.st_ctime);
  /* modification time */
  *modificationDate= convertToSqueakTime(statBuf.st_mtime);

  if (S_ISDIR(statBuf.st_mode))
    *isDirectory= true;
  else
    *sizeIfFile= statBuf.st_size;
  
  *isSymlink = S_ISLNK(statBuf.st_mode);
  *posixPermissions = statBuf.st_mode & 0777;

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


/*
 * The following is useful in a debugging context when the VM's output has been
 * directed to a log file.  It binds stdout to /dev/tty, arranging that output
 * of debugging print routines such as printOop appear on stdout.
 */
void
sqStdoutToDevTTY()
{
	if (!freopen("/dev/tty","w",stdout))
		logErrorFromErrno("sqStdoutToDevTTY freopen(\"/dev/tty\",\"w\",stdout):");
}
