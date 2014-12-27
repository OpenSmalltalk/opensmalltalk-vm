/* sqPlan9File.c -- directory operations for Plan9
 * 
 *   Copyright (C) 2014 by Alex Franchuk
 *   Adapted from work by Ian Piumarta
 *
 *   All rights reserved.
 *   
 *   This file is part of Plan9 Squeak.
 * 
 *   Permission is hereby granted, free of charge, to any person obtaining a copy
 *   of this software and associated documentation files (the "Software"), to deal
 *   in the Software without restriction, including without limitation the rights
 *   to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 *   copies of the Software, and to permit persons to whom the Software is
 *   furnished to do so, subject to the following conditions:
 * 
 *   The above copyright notice and this permission notice shall be included in
 *   all copies or substantial portions of the Software.
 * 
 *   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 *   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 *   OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 *   SOFTWARE.
 */

/* 
 * Author: alex.franchuk@gmail.com
 */

#include "sq.h"
#include "FilePlugin.h"

#include <time.h>
#include <stdio.h>
#include <string.h>

/***
	The interface to the directory primitive is path based.
	That is, the client supplies a Squeak string describing
	the path to the directory on every call. To avoid traversing
	this path on every call, a cache is maintained of the last
	path seen.
***/

/*** Constants ***/
#define ENTRY_FOUND     0
#define NO_MORE_ENTRIES 1
#define BAD_PATH        2

#define DELIMITER '/'

/*** Variables ***/
char lastPath[MAXPATHLEN+1];
int  lastPathValid = false;
Dir* openDir = NULL;
int  numEntries;


/*** Functions ***/


sqInt dir_Create(char *pathString, sqInt pathStringLength)
{
  /* Create a new directory with the given path. By default, this
     directory is created relative to the cwd. */
  char name[MAXPATHLEN+1];

  if (pathStringLength >= MAXPATHLEN)
    return false;

  strncpy(name, pathString, pathStringLength);
  name[pathStringLength] = '\0';

  return create(name, ORDWR, DMDIR) == 0;
}


sqInt dir_Delete(char *pathString, sqInt pathStringLength)
{
  /* Delete the existing directory with the given path. */
  char name[MAXPATHLEN+1];
  int i;
  if (pathStringLength >= MAXPATHLEN)
  	  return false;

  strncpy(name, pathString, pathStringLength);
  name[pathStringLength] = '\0';

  if (lastPathValid && !strcmp(lastPath, name)) {
      free(openDir);
      openDir = NULL;
      lastPathValid = false;
      lastPath[0] = '\0';
  }
  return remove(name) == 0;
}


sqInt dir_Delimitor(void)
{
  return DELIMITER;
}


time_t convertToSqueakTime(time_t unixTime);

static int maybeOpenDir(char *path)
{
  /* if the last opendir was to the same directory, re-use the directory
     pointer from last time.  Otherwise close the previous directory,
     open the new one, and save its name.  Return true if the operation
     was successful, false if not. */
	if (!lastPathValid || strcmp(lastPath, path))
    {
    	int openDirfd;
		/* invalidate the old, open the new */
		if (lastPathValid) {
			free(openDir);
			openDir = NULL;
		}

		lastPathValid = false;
		strcpy(lastPath, path);

		if ((openDirfd = open(path, OREAD)) == 0)
			return false;
		
		numEntries = dirread(openDirfd, &openDir);
		close(openDirfd);

		lastPathValid = true;
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

	int i, num;
	int nameLen= 0;
	char path[MAXPATHLEN+1];
	Dir *filedir = NULL;

	/* default return values */
	*name             = 0;
	*nameLength       = 0;
	*creationDate     = 0;
	*modificationDate = 0;
	*isDirectory      = false;
	*sizeIfFile       = 0;

	if (pathStringLength > MAXPATHLEN) {
		return BAD_PATH;
	}

	if (pathStringLength == 0) strcpy(path, ".");
	else {
		strncpy(path, pathString, pathStringLength);
		path[pathStringLength] = '\0';
	}

	/* get file or directory info */
	if (!maybeOpenDir(path))
		return BAD_PATH;

	if (numEntries == 0) {
		return NO_MORE_ENTRIES;
	}
	else if (numEntries < 0) {
		return BAD_PATH;
	}
	else if (openDir == NULL) {
		return NO_MORE_ENTRIES;
	}
	else if (index >= numEntries) {
		return NO_MORE_ENTRIES;
	}
	
	nameLen = strlen(openDir[index].name);

  	strncpy(name, openDir[index].name, nameLen);
  	*nameLength = nameLen;

	{
		char terminatedName[MAXPATHLEN];
		strncpy(terminatedName, openDir[index].name, nameLen);
		terminatedName[nameLen]= '\0';
		strcat(path, "/");
		strcat(path, terminatedName);
		if ((filedir = dirstat(path)) == NULL) {
			return ENTRY_FOUND;
		}
	}

	/* last change time */
	*creationDate = convertToSqueakTime(filedir->atime < filedir->mtime ? filedir->atime : filedir->mtime);
	/* modification time */
	*modificationDate = convertToSqueakTime(filedir->mtime);

	if (filedir->mode & DMDIR)
		*isDirectory = true;
	else
		*sizeIfFile = filedir->length;

	free(filedir);

	return ENTRY_FOUND;
}


sqInt dir_SetMacFileTypeAndCreator(char *filename, sqInt filenameSize, char *fType, char *fCreator)
{
  return true;
}

sqInt dir_GetMacFileTypeAndCreator(char *filename, sqInt filenameSize, char *fType, char *fCreator)
{
  return true;
}
