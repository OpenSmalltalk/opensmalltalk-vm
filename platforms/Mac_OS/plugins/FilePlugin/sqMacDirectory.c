/****************************************************************************
*   PROJECT: Mac directory logic
*   FILE:    sqMacDirectory.c
*   CONTENT: 
*
*   AUTHOR:  John McIntosh, and others.
*   ADDRESS: 
*   EMAIL:   johnmci@smalltalkconsulting.com
*   RCSID:   $Id: sqMacDirectory.c 1197 2005-05-31 05:51:16Z johnmci $
*
*   NOTES: See change log below.
* 
 
 Feb 2nd 2001, JMM rewrote, using more current file manager logic.
 3.0.7 return correct response on findimage
 3.0.10 Mimimal VM logic
 3.0.11 April 4th fix bug in lookupPath (users never saw it)
 3.0.14 May 2001 lookupPath needs to abort on :: can't do hardway lookup, too complicated
 3.0.17 May 24th 2001 JMM add flush vol on flush file (needed according to apple tech notes)
 3.0.19 Aug 2001 JMM make it a real plugin 
 3.2.1  Nov 2001 JMM build with Apple's project builder and convert to use StdCLib.
 3.2.1B5 Dec 27,2001 JMM alter mkdir def to make cw pro 5 happy
 3.2.1B6 Jan 2,2002 JMM make lookup faster
 3.2.2B1 Jan 18th,2002 JMM check macroman, fix issues with squeak file offset
 3.2.8b1 July 24th, 2002 JMM support for os-x plugin under IE 5.x
 3.5.1b1 May 20th, 2003 JMM isDirectory ? ENTRY_FOUND versus always found because path could be a file. 
 3.7.0bx Nov 24th, 2003 JMM gCurrentVMEncoding
 */

#include "sq.h"
#include "FilePlugin.h"
#include "sqMacUnixFileInterface.h"
#if TARGET_API_MAC_CARBON
	#include <Carbon/Carbon.h>
	#include <unistd.h>
	#include <sys/stat.h>
	extern CFStringEncoding gCurrentVMEncoding;
#else
	#if defined(__MWERKS__) && !defined(__APPLE__) && !defined(__MACH__)
		#include <unistd.h>
		int mkdir(const char *,int);
		int ftruncate(short int file,int offset);
	#endif

	#include <Files.h>
	#include <Strings.h>
#endif

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

int convertToSqueakTime(int macTime) {
	/* Squeak epoch is Jan 1, 1901, 3 non-leap years earlier than Mac one */
	return macTime + (3 * 365 * 24 * 60 * 60);
}
#if TARGET_API_MAC_CARBON
sqInt dir_Create(char *pathString, sqInt pathStringLength) {
	/* Create a new directory with the given path. By default, this
	   directory is created in the current directory. Use
	   a full path name such as "MyDisk:Working:New Folder" to
	   create folders elsewhere. */

    char cFileName[1001];

    if (pathStringLength >= 1000) {
        return false;
    }

    /* copy the file name into a null-terminated C string */
    sqFilenameFromString((char *) cFileName, (int) pathString, pathStringLength);
    
#if defined(__MWERKS__)
	{
        CFStringRef 	filePath,lastFilePath;
        CFURLRef 	    sillyThing,sillyThing2;
        FSRef	        parentFSRef;
        UniChar         buffer[1024];
        long            tokenLength;
		int err;
        
        filePath   = CFStringCreateWithBytes(kCFAllocatorDefault,(UInt8 *)cFileName,strlen(cFileName),gCurrentVMEncoding,false);
        if (filePath == nil) 
            return false;
        sillyThing = CFURLCreateWithFileSystemPath (kCFAllocatorDefault,filePath,kCFURLHFSPathStyle,true);
        CFRelease(filePath);

        lastFilePath = CFURLCopyLastPathComponent(sillyThing);
        tokenLength = CFStringGetLength(lastFilePath);
        if (tokenLength > 1024)
            return false;
        CFStringGetCharacters(lastFilePath,CFRangeMake(0,tokenLength),buffer);
        CFRelease(lastFilePath);

        sillyThing2 = CFURLCreateCopyDeletingLastPathComponent(kCFAllocatorDefault,sillyThing);

        err = CFURLGetFSRef(sillyThing2,&parentFSRef);
        CFRelease(sillyThing);
        CFRelease(sillyThing2);
        if (err == 0) {
            return false;  
        }
		err = FSCreateDirectoryUnicode(&parentFSRef,tokenLength,buffer,kFSCatInfoNone,NULL,NULL,NULL,NULL);
		
    	return (err == noErr ? 1 : 0);
    }
#else
    return mkdir(cFileName, 0777) == 0;
#endif
}
 
sqInt dir_Delete(char *pathString, sqInt pathStringLength) {
	/* Delete the existing directory with the given path. */
    char cFileName[1000];

    if (pathStringLength >= 1000) {
        return false;
    }

	if (equalsLastPath(pathString, pathStringLength))
		lastPathValid = false;

#if defined(__MWERKS__)
	{
    	/* Delete the existing directory with the given path. */
        FSSpec spec;
        OSErr  err;

        if ((err = makeFSSpec(pathString, pathStringLength,&spec))  != noErr)
            return false;
            
       	return FSpDelete(&spec) == noErr;
    }
#else
    /* copy the file name into a null-terminated C string */
    sqFilenameFromString(cFileName, (int) pathString, pathStringLength);
    return rmdir(cFileName) == 0;
#endif
}

#else
sqInt dir_Create(char *pathString, sqInt pathStringLength) {
    FSSpec spec;
    OSErr  err;
    long  createdDirID;
    
    if ((err = makeFSSpec(pathString, pathStringLength,&spec)) == -1)
        return false;
        
   	return FSpDirCreate(&spec,smSystemScript,&createdDirID) == noErr;
}

sqInt dir_Delete(char *pathString, sqInt pathStringLength) {
	/* Delete the existing directory with the given path. */
    FSSpec spec;
    OSErr  err;

    if ((err = makeFSSpec(pathString, pathStringLength,&spec)) == -1)
        return false;
        
   	return FSpDelete(&spec) == noErr;
}
#endif

sqInt dir_Delimitor(void) {
	return DELIMITOR;
}

#if TARGET_API_MAC_CARBON

sqInt dir_Lookup(char *pathString, sqInt pathStringLength, sqInt index,
  /* outputs: */
  char *name, sqInt *nameLength, sqInt *creationDate, sqInt *modificationDate,
  sqInt *isDirectory, squeakFileOffsetType *sizeIfFile, sqInt *posixPermissions, sqInt *isSymlink) {
	/* Lookup the index-th entry of the directory with the given path, starting
	   at the root of the file system. Set the name, name length, creation date,
	   creation time, directory flag, and file size (if the entry is a file).
	   Return:	0 	if a entry is found at the given index
	   			1	if the directory has fewer than index entries
	   			2	if the given path has bad syntax or does not reach a directory
	*/

	sqInt okay;
    FSSpec      spec;
    long        parentDirectory;
    OSErr       err;
    Str255      longFileName;
		FSVolumeInfoParam fsVolumeParam;
		HFSUniStr255 uniStr;
		FSVolumeInfo volumeInfo;
    
	/* default return values */
	*name             = 0;
	*nameLength       = 0;
	*creationDate     = 0;
	*modificationDate = 0;
	*isDirectory      = false;
	*sizeIfFile       = 0;

	if ((pathStringLength == 0)) {
		/* get volume info */
		fsVolumeParam.volumeName = &uniStr;
		fsVolumeParam.ioVRefNum = kFSInvalidVolumeRefNum;
		fsVolumeParam.volumeIndex = index;
		fsVolumeParam.whichInfo = 0;
		fsVolumeParam.volumeInfo = &volumeInfo;
		fsVolumeParam.ref = NULL;
		fsVolumeParam.whichInfo = kFSVolInfoCreateDate + kFSVolInfoModDate; 
		okay = PBGetVolumeInfoSync( &fsVolumeParam) == noErr;
/*
		FSGetVolumeInfo (kFSInvalidVolumeRefNum,
			index,
			NULL,
			)
*/
		if (okay) {
			CFStringRef strRef = CFStringCreateWithCharacters( kCFAllocatorDefault, uniStr.unicode, uniStr.length );
			CFMutableStringRef mStr = CFStringCreateMutableCopy(NULL, 0, strRef);
			// HFS+ imposes Unicode2.1 decomposed UTF-8 encoding on all path elements
			if (gCurrentVMEncoding == kCFStringEncodingUTF8) 
				CFStringNormalize(mStr, kCFStringNormalizationFormKC); // pre-combined
			Boolean result = CFStringGetCString(mStr, name, 256, gCurrentVMEncoding); // buffer size is to see primitiveDirectoryLookup
			CFRelease(strRef);
			CFRelease(mStr);
			if (result == true) {
				// strncpy(name, &(uniStr.unicode), uniStr.length);
				// *nameLength       = uniStr.length;
				*nameLength       = strlen(name);
				{	
					LocalDateTime local;
					
					ConvertUTCToLocalDateTime(&fsVolumeParam.volumeInfo->createDate,&local);
					*creationDate     = convertToSqueakTime(local.lowSeconds);
				}
				{	
					LocalDateTime local;
					
					ConvertUTCToLocalDateTime(&fsVolumeParam.volumeInfo->modifyDate,&local);
					*modificationDate     = convertToSqueakTime(local.lowSeconds);
				}
				*isDirectory      = true;
				*sizeIfFile       = 0;
				return ENTRY_FOUND;
			} else {
				return NO_MORE_ENTRIES;
			}
		} else {
			return NO_MORE_ENTRIES;
		}
	} else {
		/* get file or directory info */
		if (!equalsLastPath(pathString, pathStringLength)) {
 			/* lookup and cache the refNum for this path */
			err = lookupPath(pathString, pathStringLength, &spec,false,true);
 			if (err == noErr) 
				recordPath(pathString, pathStringLength, &spec);
			else 
				return BAD_PATH;
		}
	    spec = lastSpec;
		*sizeIfFile   = 0;
		okay = fetchFileInfo(index,&spec,(unsigned char *) name,true,
							&parentDirectory,isDirectory,creationDate,
							modificationDate,sizeIfFile,&longFileName);
		if (okay == noErr) {
			CFStringRef cfs= CFStringCreateWithPascalString(NULL, longFileName, gCurrentVMEncoding);
			CFMutableStringRef mStr= CFStringCreateMutableCopy(NULL, 0, cfs);
			CFRelease(cfs);
			// HFS+ imposes Unicode2.1 decomposed UTF-8 encoding on all path elements
			if (gCurrentVMEncoding == kCFStringEncodingUTF8) 
				CFStringNormalize(mStr, kCFStringNormalizationFormKC); // pre-combined
			CFStringGetCString(mStr, name, 256, gCurrentVMEncoding);
			CFRelease(mStr);

			*nameLength       = strlen(name);
			*creationDate     = convertToSqueakTime(*creationDate);
			*modificationDate = convertToSqueakTime(*modificationDate);
			return ENTRY_FOUND;
		} else
			return okay == fnfErr ? NO_MORE_ENTRIES : BAD_PATH;
	}
}

#else 

sqInt dir_Lookup(char *pathString, sqInt pathStringLength, sqInt index,
  /* outputs: */
  char *name, sqInt *nameLength, sqInt *creationDate, sqInt *modificationDate,
  sqInt *isDirectory, squeakFileOffsetType *sizeIfFile, sqInt *posixPermissions, sqInt *isSymlink) {
	/* Lookup the index-th entry of the directory with the given path, starting
	   at the root of the file system. Set the name, name length, creation date,
	   creation time, directory flag, and file size (if the entry is a file).
	   Return:	0 	if a entry is found at the given index
	   			1	if the directory has fewer than index entries
	   			2	if the given path has bad syntax or does not reach a directory
	*/

	sqInt okay;
	HVolumeParam volumeParams;
    FSSpec      spec;
    long        parentDirectory;
    OSErr       err;
    Str255      longFileName;
    
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
			err = lookupPath(pathString, pathStringLength, &spec,false,true);
 			if (err == noErr) 
				recordPath(pathString, pathStringLength, &spec);
			else 
				return BAD_PATH;
		}
	    spec = lastSpec;
				*sizeIfFile   = 0;
		okay = fetchFileInfo(index,&spec,(unsigned char *) name,true,&parentDirectory,isDirectory,creationDate,modificationDate,sizeIfFile,&longFileName);
		if (okay == noErr) {
			CopyPascalStringToC((ConstStr255Param) longFileName,name);
			*nameLength       = strlen(name);
			*creationDate     = convertToSqueakTime(*creationDate);
			*modificationDate = convertToSqueakTime(*modificationDate);
			return ENTRY_FOUND;
		} else
			return okay == fnfErr ? NO_MORE_ENTRIES : BAD_PATH;
	}
}
#endif
OSErr getSpecAndFInfo(char *filename, int filenameSize,FSSpec *spec,FInfo *finderInfo) {
    OSErr err;
    
    if ((err = makeFSSpec(filename, filenameSize,spec)) != noErr)
        return err;
        
    if ((err= FSpGetFInfo(spec,finderInfo)) != noErr) 
        return err;
        
    return noErr;
}

sqInt dir_SetMacFileTypeAndCreator(char *filename, sqInt filenameSize, char *fType, char *fCreator) {
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

sqInt dir_GetMacFileTypeAndCreator(char *filename, sqInt filenameSize, char *fType, char *fCreator) {
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
		return 0;
	}
	strncpy(lastPath,pathString,pathStringLength);
	lastPath[pathStringLength] = 0; /* string terminator */
	lastPathValid = true;
	lastSpec = *spec;
	return 0;
}


#if defined(__MWERKS__) 
int ftruncate(short int file,int offset)
{	
	ParamBlockRec pb;
    OSErr error;

	//JMM Foo FSSetForkSize FSSetForkPosition FSGetForkPosition
	pb.ioParam.ioRefNum = file;
	pb.ioParam.ioMisc = (char *) offset;
	error = PBSetEOFSync(&pb);
	return error;
}

#endif

#if defined(__MWERKS__) 

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
	if (file->mode.file_kind != __disk_file || (position = ftello(file)) < 0)
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

extern __system7present();
extern long __getcreator(long isbinary);
extern long __gettype(long isbinary);


static void set_file_type(FSSpec * spec, int binary_file)
{
	CInfoPBRec	pb;
	OSErr				ioResult;
	
	pb.hFileInfo.ioNamePtr   = spec->name;
	pb.hFileInfo.ioVRefNum   = spec->vRefNum;
	pb.hFileInfo.ioFDirIndex = 0;
	pb.hFileInfo.ioDirID     = spec->parID;
	
	if (!(ioResult = PBGetCatInfoSync(&pb)))
	{
		pb.hFileInfo.ioFlFndrInfo.fdType    = __gettype(binary_file);     /*mm-960729*/
		pb.hFileInfo.ioFlFndrInfo.fdCreator = __getcreator(binary_file);  /*mm-960729*/
		pb.hFileInfo.ioDirID                = spec->parID;
		
		ioResult = PBSetCatInfoSync(&pb);
	}
}

int	__open_file			(const char * name, __std(__file_modes) mode, __std(__file_handle) * handle);
OSErr __path2fss(const char * pathName, FSSpecPtr spec);

extern OSErr			gSqueakFileLastError; 
int	__open_file(const char * name, __file_modes mode, __file_handle * handle)
{
	FSSpec					spec;
	OSErr						ioResult;
	HParamBlockRec	pb;
	
	ioResult = __path2fss(name, &spec);
	
	if (ioResult) 
		gSqueakFileLastError = ioResult;
		
	if (__system7present())												/* mm 980424 */
	{																	/* mm 980424 */
		Boolean targetIsFolder, wasAliased;								/* mm 980424 */
		ResolveAliasFile(&spec, true, &targetIsFolder, &wasAliased);	/* mm 980424 */
	}																	/* mm 980424 */
	
	if (ioResult && (ioResult != fnfErr || mode.open_mode == __must_exist))
		return(__io_error);
	
	
#if TARGET_API_MAC_CARBON
	if (ioResult) {
        CFStringRef 	filePath;
        CFURLRef 	    sillyThing, sillyThing2;
        FSRef	        parentFSRef;
    	short int       fileRefNum;
        OSErr           err;
        UniChar         buffer[1024];
        long            tokenLength;
        
		
        filePath   = CFStringCreateWithBytes(kCFAllocatorDefault,(UInt8 *)name,strlen(name),gCurrentVMEncoding,false);
        if (filePath == nil) 
            return __io_error;
        sillyThing = CFURLCreateWithFileSystemPath (kCFAllocatorDefault,filePath,kCFURLHFSPathStyle,false);
        CFRelease(filePath);
        sillyThing2 = CFURLCreateCopyDeletingLastPathComponent(kCFAllocatorDefault,sillyThing);
        err = CFURLGetFSRef(sillyThing2,&parentFSRef);
        if (err == 0) {
            CFRelease(sillyThing);
            CFRelease(sillyThing2);
            return fnfErr;  
        }
        filePath = CFURLCopyLastPathComponent(sillyThing);
        tokenLength = CFStringGetLength(filePath);
        if (tokenLength > 1024) {
            CFRelease(filePath);
            CFRelease(sillyThing);
            CFRelease(sillyThing2);
            return(__io_error);
        }
            
        CFStringGetCharacters(filePath,CFRangeMake(0,tokenLength),buffer);

        CFRelease(filePath);
        CFRelease(sillyThing);
        CFRelease(sillyThing2);

		ioResult = FSCreateFileUnicode(&parentFSRef,tokenLength,buffer,kFSCatInfoNone,NULL,NULL,&spec);  
    	if (ioResult)
			gSqueakFileLastError = ioResult;
    	if (ioResult)
	    	return(__io_error);
	    	
        pb.ioParam.ioNamePtr    = spec.name;
    	pb.ioParam.ioVRefNum    = spec.vRefNum;
    	pb.ioParam.ioPermssn    = (mode.io_mode == __read) ? fsRdPerm : fsRdWrPerm;
    	pb.ioParam.ioMisc       = 0;
    	pb.fileParam.ioFVersNum = 0;
    	pb.fileParam.ioDirID    = spec.parID;
		set_file_type(&spec, mode.binary_io);
		ioResult = PBHOpenDFSync(&pb);  /* HH 10/25/97  was PBHOpenSync */
    	    	
    	if (ioResult)
    		return(__io_error);
    	
    	*handle = pb.ioParam.ioRefNum;
	
	    return(__no_io_error);
	}
#endif
    pb.ioParam.ioNamePtr    = spec.name;
	pb.ioParam.ioVRefNum    = spec.vRefNum;
	pb.ioParam.ioPermssn    = (mode.io_mode == __read) ? fsRdPerm : fsRdWrPerm;
	pb.ioParam.ioMisc       = 0;
	pb.fileParam.ioFVersNum = 0;
	pb.fileParam.ioDirID    = spec.parID;
	
	if (ioResult)
	{
		if (!(ioResult = PBHCreateSync(&pb)))
		{
			if (ioResult) 
				gSqueakFileLastError = ioResult;
			set_file_type(&spec, mode.binary_io);
			ioResult = PBHOpenDFSync(&pb);  /* HH 10/25/97  was PBHOpenSync */
			if (ioResult) 
				gSqueakFileLastError = ioResult;
		}
	}
	else
	{
		if (!(ioResult = PBHOpenDFSync(&pb)) && mode.open_mode == __create_or_truncate)  
		                                  /* HH 10/25/97  was PBHOpenSync */
		{
			pb.ioParam.ioMisc = 0;
			
			ioResult = PBSetEOFSync((ParmBlkPtr) &pb);
			
			if (ioResult)
				gSqueakFileLastError = ioResult;

			if (ioResult)
				PBCloseSync((ParmBlkPtr) &pb);
		} else {
			if (ioResult) 
				gSqueakFileLastError = ioResult;

		}
	}
	
	if (ioResult)
		return(__io_error);
	
	*handle = pb.ioParam.ioRefNum;
	
	return(__no_io_error);
}

#endif
