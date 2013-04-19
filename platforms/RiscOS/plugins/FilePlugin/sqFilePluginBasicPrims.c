//  A Squeak VM for RiscOS machines
//  Suited to RISC OS > 4, preferably > 5
// See www.squeak.org for much more information
//
// tim Rowledge tim@rowledge.org
//
// License: MIT License -
// Copyright (C) <2013> <tim rowledge>
//
// Permission is hereby granted, free of charge, to any person obtaining a
// copy of this software and associated documentation files (the "Software"),
// to deal in the Software without restriction, including without limitation
// the rights to use, copy, modify, merge, publish, distribute, sublicense,
// and/or sell copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
// THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
// DEALINGS IN THE SOFTWARE.
// This is sqFilePluginBasicPrims.c
// It provides the low level File calls for Squeak, with some twists to
// handle a few other-platform quirks, such as being able to open the ssame file
// for read amd read/write multiple times.
// and to keep life a little simpler within Squeak, RISC OS filenames
// are converted to a URL-lite format, mainly swapping the '/' for '.'

/* define this to get lots of debug reports  */
//#define DEBUG

/* The basic prim code for file operations. See also the platform specific
 * files typically named 'sq{blah}Directory.c' for details of the directory
 * handling code.
 */

#include "oslib/osfind.h"
#include "oslib/osfscontrol.h"
#include "oslib/osargs.h"
#include "oslib/osgbpb.h"
#include "oslib/osfile.h"
#include "sq.h"
#include "FilePlugin.h"

/***
	The state of a file is kept in the following structure,
	which is stored directly in a Squeak bytes object.
	NOTE: The Squeak side is responsible for creating an
	object with enough room to store sizeof(SQFile) bytes.

	The session ID is used to detect stale file objects--
	files that were still open when an image was written.
	The file pointer of such files is meaningless.

	Files are always opened in binary mode; Smalltalk code
	does (or someday will do) line-end conversion if needed.

	Writeable files are opened read/write. The stdio spec
	requires that a positioning operation be done when
	switching between reading and writing of a read/write
	filestream. The lastOp field records whether the last
	operation was a read or write operation, allowing this
	positioning operation to be done automatically if needed.

	typedef struct {
		int		sessionID;
		File	*file;
		int		writable;
		squeakFileOffsetType		fileSize;
		int		lastOp;  // 0 = uncommitted, 1 = read, 2 = write -
		(used for RISCOS specific code to hold file postion pointer)
	} SQFile;

For this perversion of the filesystem we need to do some trickery to attempt to
persuade RISC OS to pretend to allow multiple openings of one file. The approach
 is to open files with SWIs and keep a list of canoncalized filenames. When open
ing a file we search for a matching filename and if found we use the same fileid
 number. Since Squeak uses a really annoying position/read/write api (to match p
osix I guess) we have to cache the position and use it in later read/writes.

w/r
file not open (name not in list)
h = openup (rw)
if h = null
	h = openout  (w, new file created)
create list entry - name, handle, refCt
sqFile->file = h
sqFile->writable = true
return

w/r
file open (name in list)
h = list entry->handle
sqFile->file = h
sqFile->writable = true
return

r
file not open
h = openup
if h = null
	h = openin
create list entry
sqFile->file = h
sqFile->writable = false

File Open
canonicalize filename
scan list for name match
no match
	open file r or rw
	add name/id to list
		create new list item
match
	extract id
	increment id refct
fillin FILE

File Close
scan list for id
decref id
close file

***/

typedef struct OpenFileListEntry {
	struct OpenFileListEntry *next;
	os_fw handle;
	int refCt;
	char name[1];
} OpenFileListEntry;

#define FILE_HANDLE(f) (os_fw)(f)->file
#define FILE_POSITION(f) (f)->lastOp
#define FAIL() return interpreterProxy->primitiveFail()

/*** Constants ***/


/*** Variables ***/
int thisSession = 0;
extern struct VirtualMachine * interpreterProxy;
OpenFileListEntry *openFileListRoot = NULL;
char cFilename[MAXDIRNAMELENGTH];

/* linked list & entry management */

static void *findFileEntry(char *fName) {
OpenFileListEntry *entry;
	entry = openFileListRoot;
	while(entry) {
		if(strcmp(entry->name, fName) == 0) return entry;
		entry = entry->next;
	}
	return NULL;
}

static void *findFileEntryByHandle(os_fw handle) {
OpenFileListEntry *entry;
	entry = openFileListRoot;
	while(entry) {
		if(entry->handle == handle) return entry;
		entry = entry->next;
	}
	return NULL;
}

static OpenFileListEntry *addToOpenFileList(char *fName, os_fw handle) {
/* create a new entry in the linkedlist of open files.
 * If the calloc fails, return NULL which will in truen go back to the
 * prim and fail it cleanly.
 * copy the fName into the new entry so the fName string can be freed later
 */
OpenFileListEntry *entry;
	entry = (OpenFileListEntry*) calloc(1, sizeof(OpenFileListEntry) + strlen(fName));
	if ( entry == NULL) {
		return NULL;
	}
	strcpy(entry->name, fName);
	entry->handle = handle;
	entry->next = openFileListRoot;
	entry->refCt = 2;
	openFileListRoot = entry;
	return openFileListRoot;
}

/*
 * removeFromOpenFileList:
 * Remove the given entry from the list of open files.
 * free it, if found.
 */
static int removeFromOpenFileList(OpenFileListEntry *entry) {
OpenFileListEntry *prevEntry;

	/* Unlink the entry from the module chain */
	if(entry == openFileListRoot) {
		openFileListRoot = entry->next;
	} else {
		prevEntry = openFileListRoot;
		while(prevEntry->next != entry)
			prevEntry = prevEntry->next;
		prevEntry->next = entry->next;
	}
	free(entry);
	return true;
}

OpenFileListEntry * entryForFileNamed(char * fname, int writeFlag) {
/* return an entry for the file named fname
 * if there is an entry already in the list, just return a pointer to it.
 * if not, create one
 *	open the file rw
 * then return it
 * return NULL if opening failed
 */
OpenFileListEntry * entry;
os_fw handle;
	entry = findFileEntry(fname);
	if (entry != NULL) {
		/* the file is already open so all we do is increment the
		 * reference count  and return the entry pointer */
		entry->refCt += 2;
		if (entry->refCt < 0 ) {
			/* the value wrapped - eek that means > 1 billion opens! - so
			 * use the old LPD refCt trick and set refCt to -1, inc & dec by
			 * 2 and thus an overflowed refCt can never hit 0.
			 */
			entry->refCt = -1;
		}
		PRINTF(("\\t file entry %s (%0x):%d\n",entry->name, entry->handle, entry->refCt));
		return entry;
	}
	/* the file is not open so open it */
	if ( writeFlag) {
		/* First try to open an existing file as read/write: */
		PRINTF(("\\t entryForFileNamed: open existing file %s\n", fname));
		xosfind_openupw(osfind_NO_PATH, fname, (char *)NULL, &handle);
		if (handle == NULL) {
			/* Previous call fails if file does not exist. In that case,
			   try opening it in write mode to create a new, empty file.
			*/
			PRINTF(("\\t sentryForFileNamed: now try to open new file\n"));
			xosfind_openoutw(osfind_NO_PATH, fname, (char *)NULL, &handle);
			if (handle == NULL) {
				PRINTF(("\\t sentryForFileNamed: failed(w)\n"));
				return NULL;
			} else {
				xosfile_set_type(fname, (bits)0xFFF);
			}
		}
	} else{
		/* read only requested */
		xosfind_openinw(osfind_NO_PATH, fname, (char *)NULL, &handle);
		if ( handle ==NULL) {
			PRINTF(("\\t sentryForFileNamed: failed(r)\n"));
			return NULL;
		}
	}
	entry = addToOpenFileList(fname, handle);
	return entry;
}


/* primitive support */

sqInt sqFileOpen(SQFile *f, char* sqFileName, sqInt sqFileNameSize, sqInt writeFlag) {
/* Opens the given file using the supplied sqFile structure
 * to record its state. Fails with no side effects if f is
 * already open. Files are always opened in binary mode;
 * Squeak must take care of any line-end character mapping.
 */
int extent;
OpenFileListEntry * entry;

	/* don't open the file if it's already open */
	if (sqFileValid(f)) {
		PRINTF(("\\t sqFileOpen: attempt to open already known open file\n"));
		FAIL();
	}

	if (!canonicalizeFilenameToString(sqFileName, sqFileNameSize, cFilename)) FAIL();

	PRINTF(("\\t sqFileOpen: canonicalized filename: %s\n", cFilename));

	entry = entryForFileNamed(cFilename, writeFlag);

	if (entry == NULL) {
		PRINTF(("\\t sqFileOpen: failed to open file\n"));
		f->file = 0;
		f->sessionID = 0;
		f->fileSize = 0;
		f->writable = true;
		FAIL();
	}

	if (writeFlag) {
		f->writable = true;
	} else {
		/* open as readable file */
		f->writable = false;
	}

	f->file = (FILE*)entry->handle;
	FILE_POSITION(f) = 0;

	f->sessionID = thisSession;
	/* compute and cache file size */
	xosargs_read_extw(FILE_HANDLE(f), &extent);
	f->fileSize = extent;
	return true;
}

sqInt sqFileClose(SQFile *f) {
	/* Close the given file. */
	OpenFileListEntry *entry;

	if (!sqFileValid(f)) {
		PRINTF(("\\t sqFileClose: attempt to close already closed file\n"));
		FAIL();
	}
	entry = findFileEntryByHandle(FILE_HANDLE(f));
	if (entry == NULL) {
	PRINTF(("\\t sqFileClose: failed\n"));
		FAIL();
	}
	PRINTF(("\\t close file entry %s (%0x):%d\n",entry->name, entry->handle, entry->refCt));
	entry->refCt -= 2;
	if (entry->refCt == 0) {
		/* all uses closed, so close file and remove entry */
		PRINTF(("\\t sqFileClose: final close of %s\n", entry->name));
		xosfind_closew(FILE_HANDLE(f));
		removeFromOpenFileList(entry);
	}
	f->file = NULL;
	f->sessionID = 0;
	f->writable = false;
	f->fileSize = 0;
	return true;
}

sqInt sqFileAtEnd(SQFile *f) {
/* Return true if the file's read/write head is at the end of the file.*/

	if (!sqFileValid(f)) {
		PRINTF(("\\t sqFileAtEnd: attempt to query invalid file\n"));
		FAIL();
	}
	return FILE_POSITION(f) == f->fileSize;
}

squeakFileOffsetType sqFileGetPosition(SQFile *f) {
/* Return the current position of the file's read/write head. */

	if (!sqFileValid(f)) {
		PRINTF(("\\t sqFileGetPosition: attempt to query invalid file\n"));
		FAIL();
	}
	PRINTF(("\\t sqFileGetPosition: file %x at %d\n", FILE_HANDLE(f), FILE_POSITION(f)));
	return FILE_POSITION(f);
}

sqInt sqFileSetPosition(SQFile *f, squeakFileOffsetType position) {
/* Set the file's read/write head to the given position. */
	if (!sqFileValid(f)) {
		PRINTF(("\\t sqFileSetPosition: attempt to set invalid file\n"));
		FAIL();
	}
	PRINTF(("\\t sqFileSetPosition: file %x to %d\n", FILE_HANDLE(f), position));
	FILE_POSITION(f) = position;
	return true;
}

squeakFileOffsetType sqFileSize(SQFile *f) {
/* Return the length of the given file. */
	if (!sqFileValid(f)) {
		PRINTF(("\\t sqFileSize: attempt to query invalid file\n"));
		FAIL();
	}
	return f->fileSize;
}

sqInt sqFileFlush(SQFile *f) {
/* Return the length of the given file. */
	if (!sqFileValid(f)) FAIL();
	xosargs_ensurew(FILE_HANDLE(f));
	return true;
}

sqInt sqFileTruncate(SQFile *f,squeakFileOffsetType offset) {
/* Truncate the file*/
int extent;
	if (!sqFileValid(f)) FAIL();
	if (xosargs_set_extw(FILE_HANDLE(f), offset) != NULL) {
		FAIL();
	}
	xosargs_read_extw(FILE_HANDLE(f), &extent);
	f->fileSize = extent;
	return true;
}

sqInt sqFileStdioHandlesInto(SQFile files[3]) {
	return 0;
}

size_t sqFileReadIntoAt(SQFile *f, size_t count, char* byteArrayIndex, size_t startIndex) {
/* Read count bytes from the given file into byteArray starting at
 * startIndex. byteArray is the address of the first byte of a
 * Squeak bytes object (e.g. String or ByteArray). startIndex
 * is a zero-based index; that is a startIndex of 0 starts writing
 * at the first byte of byteArray.
 */
byte *dst;
int bytesUnread;
	if (!sqFileValid(f)) {
		PRINTF(("\\t sqFileReadIntoAt: attempt to read invalid file\n"));
		FAIL();
	}
	dst = (byte *) (byteArrayIndex + startIndex);

	xosgbpb_read_atw(FILE_HANDLE(f), dst, count, FILE_POSITION(f), &bytesUnread)
;
	FILE_POSITION(f) += (count - bytesUnread);
	PRINTF(("\\t sqFileReadIntoAt: read %d bytes of %d from file %x to %0x\n", count - bytesUnread, count, (int)FILE_HANDLE(f), (int)dst));
	return count - bytesUnread;
}

size_t sqFileWriteFromAt(SQFile *f, size_t count, char* byteArrayIndex, size_t startIndex) {
/* Write count bytes to the given writable file starting at startIndex
 * in the given byteArray. (See comment in sqFileReadIntoAt for interpretation
 * of byteArray and startIndex).
 */
byte *src;
int bytesUnwritten;
int extent;

	if (!(sqFileValid(f) && f->writable)) {
		PRINTF(("\\t sqFileWriteFromAt: attempt to write to invalid file\n"));
		FAIL();
	}
	src = (byte *) (byteArrayIndex + startIndex);
	xosgbpb_write_atw(FILE_HANDLE(f), src, count, FILE_POSITION(f), &bytesUnwritten);
	FILE_POSITION(f) += (count - bytesUnwritten);
	PRINTF(("\\t sqFileWriteFromAt: wrote %d bytes of %d from %0x to file %x\n", count - bytesUnwritten, count, (int)src, (int)f->file));

	xosargs_read_extw(FILE_HANDLE(f), &extent);
	f->fileSize = extent;

	if (bytesUnwritten != 0) {
		PRINTF(("\\t sqFileWriteFromAt: failed\n"));
		FAIL();
	}
	return count;
}

sqInt sqFileRenameOldSizeNewSize(char* oldNameIndex, sqInt oldNameSize, char* newNameIndex, sqInt newNameSize) {
char cNewName[MAXDIRNAMELENGTH];

	if (!canonicalizeFilenameToString(oldNameIndex, oldNameSize, cFilename)) FAIL();
	if (!canonicalizeFilenameToString(newNameIndex, newNameSize, cNewName)) FAIL();

	if (xosfscontrol_rename(cFilename, cNewName) != NULL) {
		FAIL();
	}
	return true;
}

sqInt sqFileDeleteNameSize(char * sqFileName, sqInt sqFileNameSize) {
os_error *err;
fileswitch_object_type objtype;
bits loadaddr, execaddr;
int size;
fileswitch_attr attr;

	if (!canonicalizeFilenameToString(sqFileName, sqFileNameSize, cFilename)) FAIL();;

	PRINTF(("\\t sqFileDeleteNameSize: canonicalized name %s\n",cFilename));

	err = xosfile_delete( cFilename,
		&objtype,
		&loadaddr,
		&execaddr,
		&size,
		&attr);
	if (err != NULL) {
		PRINTF(("\\t sqFileDeleteNameSize: failed\n"));
		FAIL();
	}
	return true;
}

sqInt sqFileThisSession(void) {
	return thisSession;
}

sqInt sqFileValid(SQFile *f) {
	return (
		(f != NULL) &&
		(f->file != NULL) &&
		(f->sessionID == thisSession));
}

sqInt sqFileInit(void) {
/* Create a session ID that is unlikely to be repeated.
 * Zero is never used for a valid session number.
 * Should be called once at startup time.
 */
#if VM_PROXY_MINOR > 6
	thisSession = interpreterProxy->getThisSessionID();
#else
	thisSession = ioMSecs() + time(NULL);
#endif
	if (thisSession == 0) thisSession = 1;	/* don't use 0 */
	return true;
}

sqInt sqFileShutdown(void) {
/* might be  good place to close files */
OpenFileListEntry *entry;
	entry = openFileListRoot;
	while(entry) {
		xosfind_closew(entry->handle);
		entry = entry->next;
	}
	return true;
}

