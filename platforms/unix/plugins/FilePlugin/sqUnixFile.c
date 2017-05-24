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

#include <sys/stat.h>
#include <sys/types.h>

#include <dirent.h>
#include <errno.h>
#include <limits.h>
#include <stdio.h>
#include <string.h>
#include <time.h>
#include <unistd.h>

#include "sq.h"
#include "sqStrSafe.h"
#include "sqUnixCharConv.h"
#include "FilePlugin.h" /* must be included after sq.h */

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
static char lastPath[PATH_MAX];
static int lastPathValid = false;
static int lastIndex = -1;
static DIR *openDir = NULL;

/*** Functions ***/

extern time_t convertToSqueakTime(time_t unixTime);

sqInt dir_Create(char *pathString, sqInt pathStringLength)
{
	/* Create a new directory with the given path. By default, this
	   directory is created relative to the cwd.
	*/
	char unixPath[PATH_MAX];

	if (pathStringLength >= sizeof(unixPath))
		return false;
	if (sq2uxPath(pathString, pathStringLength, unixPath, sizeof(unixPath) - 1, 1) == 0)
		return false;

	return mkdir(unixPath, 0777) == 0;	/* rwxrwxrwx & ~umask */
}

sqInt dir_Delete(char *pathString, sqInt pathStringLength)
{
	/* Delete the existing directory with the given path. */
	char unixPath[PATH_MAX];

	if (pathStringLength >= sizeof(unixPath))
		return false;
	if (sq2uxPath(pathString, pathStringLength, unixPath, sizeof(unixPath) - 1, 1) == 0)
		return false;

	if (lastPathValid && strcmp(lastPath, unixPath) == 0) {
		closedir(openDir);
		lastPathValid = false;
		lastIndex = -1;
		strSafeCpy(lastPath, "", sizeof(lastPath));
	}
	return rmdir(unixPath) == 0;
}

sqInt dir_Delimitor(void)
{
	return DELIMITER;
}

static int maybeOpenDir(char *unixPath)
{
	/* If the last opendir was to the same directory, re-use the directory
	   pointer from last time.  Otherwise close the previous directory,
	   open the new one, and save its name.  Return true if the operation
	   was successful, false if not.
	*/
	if (!lastPathValid || strcmp(lastPath, unixPath) != 0) {
		/* invalidate the old, open the new */
		if (lastPathValid)
			closedir(openDir);
		lastPathValid = false;
		if (strSafeCpy(lastPath, unixPath, sizeof(lastPath)) >= sizeof(lastPath))
			return false;
		openDir = opendir(unixPath);
		if (openDir == NULL)
			return false;
		lastPathValid = true;
		lastIndex = 0;	/* first entry is index 1 */
	}
	return true;
}

#if PharoVM
sqInt dir_Lookup(char *pathString, sqInt pathStringLength, sqInt index,
/* outputs: */ char *name, sqInt * nameLength,
		 sqInt * creationDate, sqInt * modificationDate,
		 sqInt * isDirectory, squeakFileOffsetType * sizeIfFile,
		 sqInt * posixPermissions, sqInt * isSymlink)
#else
sqInt dir_Lookup(char *pathString, sqInt pathStringLength, sqInt index,
/* outputs: */ char *name, sqInt * nameLength,
		 sqInt * creationDate, sqInt * modificationDate,
		 sqInt * isDirectory, squeakFileOffsetType * sizeIfFile)
#endif
{
	/* Lookup the index-th entry of the directory with the given path, starting
	   at the root of the file system. Set the name, name length, creation date,
	   creation time, directory flag, and file size (if the entry is a file).
	   Return:    0       if a entry is found at the given index
	   1  if the directory has fewer than index entries
	   2  if the given path has bad syntax or does not reach a directory
	 */

	char unixPath[PATH_MAX];
	struct dirent *dirEntry = NULL;
	struct stat statBuf;
	int i;

	/* default return values */
	strSafeCpy(name, "", NAME_MAX);
	*nameLength = 0;
	*creationDate = 0;
	*modificationDate = 0;
	*isDirectory = false;
	*sizeIfFile = 0;
#if PharoVM
	*posixPermissions = 0;
	*isSymlink = false;
#endif

	if (pathStringLength == 0) {
		strSafeCpy(unixPath, ".", sizeof(unixPath));
	} else {
		if (pathStringLength >= sizeof(unixPath))
			return BAD_PATH;
		if (sq2uxPath(pathString, pathStringLength, unixPath, sizeof(unixPath) - 1, 1) == 0)
			return BAD_PATH;
	}

	/* get file or directory info */
	if (!maybeOpenDir(unixPath))
		return BAD_PATH;

	if (++lastIndex == index) {
		index = 1;	/* fake that the dir is rewound and we want the first entry */
	} else {
		rewinddir(openDir);	/* really rewind it, and read to the index */
		lastIndex = index;
	}

	i = 0;
	while (i < index) {
		do {
			/* readdir() returns NULL on error or if it reaches
			   the end of the dir and doesn't reset errno in the
			   second case, so we must reset it before checking
			   the return value and errno
			 */
			errno = 0;
			dirEntry = readdir(openDir);
		} while (dirEntry == NULL && errno == EINTR);

		if (dirEntry == NULL)
			return NO_MORE_ENTRIES;

		/* ignore '.' and '..' (these are not *guaranteed* to be first) */
		if (strcmp(dirEntry->d_name, ".") != 0
			&& strcmp(dirEntry->d_name, "..") != 0)
			++i;
	}

	if (strSafeCat(unixPath, "/", sizeof(unixPath)) >= sizeof(unixPath))
		return BAD_PATH;
	if (strSafeCat(unixPath, dirEntry->d_name, sizeof(unixPath)) >= sizeof(unixPath))
		return BAD_PATH;

	*nameLength = ux2sqPath(dirEntry->d_name, strlen(dirEntry->d_name), name, NAME_MAX - 1, 0);

	if (stat(unixPath, &statBuf) != 0
		&& lstat(unixPath, &statBuf) != 0) {
		/* We can't stat the entry, but failing here would invalidate
		   the whole directory --bertf */
		return ENTRY_FOUND;
	}

	/* last change time */
	*creationDate = convertToSqueakTime(statBuf.st_ctime);
	/* modification time */
	*modificationDate = convertToSqueakTime(statBuf.st_mtime);

	if (S_ISDIR(statBuf.st_mode))
		*isDirectory = true;
	else
		*sizeIfFile = statBuf.st_size;

#if PharoVM
	*isSymlink = S_ISLNK(statBuf.st_mode);
	*posixPermissions = statBuf.st_mode & 0777;
#endif

	return ENTRY_FOUND;
}

#if PharoVM
sqInt dir_EntryLookup(char *pathString, sqInt pathStringLength,
		      char *nameString, sqInt nameStringLength,
/* outputs: */ char *name, sqInt * nameLength,
		      sqInt * creationDate, sqInt * modificationDate,
		      sqInt * isDirectory, squeakFileOffsetType * sizeIfFile,
		      sqInt * posixPermissions, sqInt * isSymlink)
#else
sqInt dir_EntryLookup(char *pathString, sqInt pathStringLength,
		      char *nameString, sqInt nameStringLength,
/* outputs: */ char *name, sqInt * nameLength,
		      sqInt * creationDate, sqInt * modificationDate,
		      sqInt * isDirectory, squeakFileOffsetType * sizeIfFile)
#endif
{
	/* Lookup the given name in the given directory,
	   Set the name, name length, creation date,
	   creation time, directory flag, and file size (if the entry is a file).
	   Return:    0       if a entry is found at the given index
	   1  if there is no such entry in the directory
	   2  if the given path has bad syntax or does not reach a directory
	 */

	char unixPath[PATH_MAX];
	char terminatedName[NAME_MAX];
	struct stat statBuf;

	/* default return values */
	strSafeCpy(name, "", NAME_MAX);
	*nameLength = 0;
	*creationDate = 0;
	*modificationDate = 0;
	*isDirectory = false;
	*sizeIfFile = 0;
#if PharoVM
	*posixPermissions = 0;
	*isSymlink = false;
#endif

	if (pathStringLength == 0) {
		strSafeCpy(unixPath, ".", sizeof(unixPath));
	} else {
		if (pathStringLength >= sizeof(unixPath))
			return BAD_PATH;
		if (sq2uxPath(pathString, pathStringLength, unixPath, sizeof(unixPath) - 1, 1) == 0)
			return BAD_PATH;
	}

	if (strSafeCpyLen(terminatedName, nameString, nameStringLength, sizeof(terminatedName))
		>= sizeof(terminatedName))
		return BAD_PATH;
	if (strSafeCat(unixPath, "/", sizeof(unixPath)) >= sizeof(unixPath))
		return BAD_PATH;
	if (strSafeCat(unixPath, terminatedName, sizeof(unixPath)) >= sizeof(unixPath))
		return BAD_PATH;

	if (stat(unixPath, &statBuf) != 0
		&& lstat(unixPath, &statBuf) != 0)
		return NO_MORE_ENTRIES;

	/* To match the results of dir_Lookup(), copy back the file name */
	*nameLength = ux2sqPath(nameString, nameStringLength, name, NAME_MAX - 1, 0);
	/* last change time */
	*creationDate = convertToSqueakTime(statBuf.st_ctime);
	/* modification time */
	*modificationDate = convertToSqueakTime(statBuf.st_mtime);

	if (S_ISDIR(statBuf.st_mode))
		*isDirectory = true;
	else
		*sizeIfFile = statBuf.st_size;

#if PharoVM
	*isSymlink = S_ISLNK(statBuf.st_mode);
	*posixPermissions = statBuf.st_mode & 0777;
#endif

	return ENTRY_FOUND;
}

/* unix files are untyped, and the creator is correct by default */

sqInt dir_SetMacFileTypeAndCreator(char *filename, sqInt filenameSize,
				   char *fType, char *fCreator)
{
	return true;
}

sqInt dir_GetMacFileTypeAndCreator(char *filename, sqInt filenameSize,
				   char *fType, char *fCreator)
{
	return true;
}

/*
 * The following is useful in a debugging context when the VM's output has been
 * directed to a log file.  It binds stdout to /dev/tty, arranging that output
 * of debugging print routines such as printOop appear on stdout.
 */
void sqStdoutToDevTTY()
{
	if (!freopen("/dev/tty", "w", stdout))
		perror("sqStdoutToDevTTY freopen(\"/dev/tty\",\"w\",stdout):");
}
