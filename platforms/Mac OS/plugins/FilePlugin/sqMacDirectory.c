/* 
 
 Feb 2nd 2001, JMM rewrote, using more current file manager logic.
 3.0.7 return correct response on findimage
 3.0.10 Mimimal VM logic
 3.0.11 April 4th fix bug in lookupPath (users never saw it)
 3.0.14 May 2001 lookupPath needs to abort on :: can't do hardway lookup, too complicated
 3.0.17 May 24th 2001 JMM add flush vol on flush file (needed according to apple tech notes)
 3.0.19 Aug 2001 JMM make it a real plugin 
 */

#include "sq.h"
#include "FilePlugin.h"
#include "sqMacFileLogic.h"

/* End of adjustments for pluginized VM */

#include <Files.h>
#include <Strings.h>

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

#define DELIMITOR ':'
#define MAX_PATH 2000

/*** Variables ***/
char lastPath[MAX_PATH + 1];
int  lastPathValid = false;
FSSpec lastSpec;

/*** Functions ***/
int convertToSqueakTime(int macTime);
int equalsLastPath(char *pathString, int pathStringLength);
int recordPath(char *pathString, int pathStringLength, FSSpec *spec);
OSErr getSpecAndFInfo(char *filename, int filenameSize,FSSpec *spec,FInfo *finderInfo);
int ftruncate(FILE	*file,int offset);
									 								 
int convertToSqueakTime(int macTime) {
	/* Squeak epoch is Jan 1, 1901, 3 non-leap years earlier than Mac one */
	return macTime + (3 * 365 * 24 * 60 * 60);
}

int dir_Create(char *pathString, int pathStringLength) {
	/* Create a new directory with the given path. By default, this
	   directory is created in the current directory. Use
	   a full path name such as "MyDisk:Working:New Folder" to
	   create folders elsewhere. */

    //JMM tests create file in Vm directory, other place, other volume
    
    FSSpec spec;
    OSErr  err;
    long  createdDirID;
    
    if ((err = makeFSSpec(pathString, pathStringLength,&spec)) == -1)
        return false;
        
   	return FSpDirCreate(&spec,smSystemScript,&createdDirID) == noErr;
}

int dir_Delete(char *pathString, int pathStringLength) {
	/* Delete the existing directory with the given path. */
    FSSpec spec;
    OSErr  err;

    if ((err = makeFSSpec(pathString, pathStringLength,&spec)) == -1)
        return false;
        
   	return FSpDelete(&spec) == noErr;
}

int dir_Delimitor(void) {
	return DELIMITOR;
}

int dir_Lookup(char *pathString, int pathStringLength, int index,
  /* outputs: */
  char *name, int *nameLength, int *creationDate, int *modificationDate,
  int *isDirectory, int *sizeIfFile) {
	/* Lookup the index-th entry of the directory with the given path, starting
	   at the root of the file system. Set the name, name length, creation date,
	   creation time, directory flag, and file size (if the entry is a file).
	   Return:	0 	if a entry is found at the given index
	   			1	if the directory has fewer than index entries
	   			2	if the given path has bad syntax or does not reach a directory
	*/

	int okay;
	HVolumeParam volumeParams;
	CInfoPBRec dirParams;
    FSSpec      spec;
    Boolean     isFolder;
    OSErr       err;
    
	/* default return values */
	*name             = 0;
	*nameLength       = 0;
	*creationDate     = 0;
	*modificationDate = 0;
	*isDirectory      = false;
	*sizeIfFile       = 0;

	if ((pathStringLength == 0)) {
		/* get volume info */
		volumeParams.ioNamePtr = (unsigned char *) name;
		volumeParams.ioVRefNum = 0;
		volumeParams.ioVolIndex = index;
		okay = PBHGetVInfoSync((HParmBlkPtr) &volumeParams) == noErr;
		if (okay) {
			CopyPascalStringToC((ConstStr255Param) name,name);
			*nameLength       = strlen(name);
			*creationDate     = convertToSqueakTime(volumeParams.ioVCrDate);
			*modificationDate = convertToSqueakTime(volumeParams.ioVLsMod);
			*isDirectory      = true;
			*sizeIfFile       = 0;
			return ENTRY_FOUND;
		} else {
			return NO_MORE_ENTRIES;
		}
	} else {
		/* get file or directory info */
		if (!equalsLastPath(pathString, pathStringLength)) {
			/* lookup and cache the refNum for this path */
			err = lookupPath(pathString, pathStringLength, &spec,false);
			if (err == noErr) 
				recordPath(pathString, pathStringLength, &spec);
			else 
				return BAD_PATH;
		}
	    spec = lastSpec;
		okay = fetchFileInfo(&dirParams,index,&spec,(unsigned char *) name,true,&isFolder);
		if (okay) {
			CopyPascalStringToC((ConstStr255Param) name,name);
			*nameLength       = strlen(name);
			*creationDate     = convertToSqueakTime(dirParams.hFileInfo.ioFlCrDat);
			*modificationDate = convertToSqueakTime(dirParams.hFileInfo.ioFlMdDat);
			if (((dirParams.hFileInfo.ioFlAttrib & kioFlAttribDirMask) != 0) || isFolder) {
				*isDirectory  = true;
				*sizeIfFile   = 0;
			} else {
				*isDirectory  = false;
				*sizeIfFile   = dirParams.hFileInfo.ioFlLgLen;
			}
			return ENTRY_FOUND;
		} else
			return NO_MORE_ENTRIES;
	}
}

OSErr getSpecAndFInfo(char *filename, int filenameSize,FSSpec *spec,FInfo *finderInfo) {
    OSErr err;
    
    if ((err = makeFSSpec(filename, filenameSize,spec)) != noErr)
        return err;
        
    if ((err= FSpGetFInfo(spec,finderInfo)) != noErr) 
        return err;
        
    return noErr;
}

dir_SetMacFileTypeAndCreator(char *filename, int filenameSize, char *fType, char *fCreator) {
	/* Set the Macintosh type and creator of the given file. */
	/* Note: On other platforms, this is just a noop. */

    FSSpec spec;
    FInfo   finderInfo;
    
    if (getSpecAndFInfo(filename,filenameSize,&spec,&finderInfo) != noErr)
        return false;
       
	finderInfo.fdType = *((int *) fType);
	finderInfo.fdCreator = *((int *) fCreator);
	
    return FSpSetFInfo(&spec,&finderInfo) == noErr;
}

dir_GetMacFileTypeAndCreator(char *filename, int filenameSize, char *fType, char *fCreator) {
	/* Get the Macintosh type and creator of the given file. */
	/* Note: On other platforms, this is just a noop. */

    FSSpec spec;
    FInfo   finderInfo;
    
    if (getSpecAndFInfo(filename,filenameSize,&spec,&finderInfo) != noErr)
        return false;
       
	*((int *) fType) = finderInfo.fdType;
	*((int *) fCreator) = finderInfo.fdCreator;

	return true;
}


int equalsLastPath(char *pathString, int pathStringLength) {
	/* Return true if the lastPath cache is valid and the
	   given Squeak string equals it. */

	int i, ch;

	if (!lastPathValid ||
		(pathStringLength > MAX_PATH)) {
			return false;
	}

	for (i = 0; i < pathStringLength; i++) {
		ch = lastPath[i];
		if ((ch == 0) || (ch != pathString[i])) return false;
	}
	return lastPath[i] == 0;
}




int recordPath(char *pathString, int pathStringLength, FSSpec *spec) {
	/* Copy the given Squeak string into the lastPath cache. */

	if (pathStringLength > MAX_PATH) {
		lastPath[0] = 0; /* set to empty string */
		lastPathValid = false;
		lastSpec = *spec;
		return;
	}
	strncpy(lastPath,pathString,pathStringLength);
	lastPath[pathStringLength] = 0; /* string terminator */
	lastPathValid = true;
	lastSpec = *spec;
}



#if !defined ( __MPW__ ) &&  !defined( __APPLE__ ) && !defined( __MACH__)


#include <ansi_files.h>
#include <buffer_io.h>

int fflush(FILE * file)
{
	fpos_t	position;                    /* mm 970708 */
	ParamBlockRec pb;
    OSErr error;
	
	if (!file)
		return(__flush_all());
	
	if (file->state.error || file->mode.file_kind == __closed_file)
		return(EOF);
	
	if (file->mode.io_mode == __read)		/* mm 980430 */
		return 0;							/* mm 980430 */
	
	if (file->state.io_state >= __rereading)
		file->state.io_state = __reading;
	
	if (file->state.io_state == __reading)
		file->buffer_len = 0;
	
	if (file->state.io_state != __writing)
	{
		file->state.io_state = __neutral;  /* mm 970905 */
		return(0);
	}
	
#ifndef _No_Disk_File_OS_Support
	if (file->mode.file_kind != __disk_file || (position = ftell(file)) < 0)
		position = 0;
#else
	position = 0;
#endif
	
	if (__flush_buffer(file, NULL))
	{
		set_error(file);
		return(EOF);
	}
	
	file->state.io_state = __neutral;
	file->position       = position;
	file->buffer_len     = 0;
	
	pb.ioParam.ioRefNum = file->handle;
    error = PBFlushFileSync(&pb);
	error = GetVRefNum(pb.ioParam.ioRefNum,&pb.volumeParam.ioVRefNum);
	pb.volumeParam.ioNamePtr = nil;
	error = PBFlushVolSync(&pb);


	return(0);
}

int ftruncate(FILE	*file,int offset)
{	
	ParamBlockRec pb;
    OSErr error;

	pb.ioParam.ioRefNum = file->handle;
	pb.ioParam.ioMisc = (char *) offset;
	error = PBSetEOFSync(&pb);
	return error;
}
#endif

