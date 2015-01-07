/****************************************************************************
*   PROJECT: Mac filespec interface.
*   FILE:    sqMacFileLogic.c
*   CONTENT: 
*
*   AUTHOR:  John McIntosh,Karl Goiser, and others.
*   ADDRESS: 
*   EMAIL:   johnmci@smalltalkconsulting.com
*   RCSID:   $Id: sqMacFileLogic.c 1289 2006-01-09 04:03:26Z johnmci $
*
*   NOTES: See change log below.
*	11/01/2001 JMM Consolidation of fsspec handling for os-x FSRef transition.
*	12/27/2001 JMM Because of how os-x handles metadata I had to change how navgetfile functions
*	1/1/2002 JMM some cleanup to streamline path creation to minimize io & carbon cleanup
*	1/18/2002 JMM recheck macroman, fix dir size problem on os-9, do squeak file offset type
*   4/23/2002 JMM fix how image is found for os-9 for bundled applications
*   5/12/2002 JMM add logic to enable you to put plugins beside macclassic VM
*   3.2.8b1 July 24th, 2002 JMM support for os-x plugin under IE 5.x
    3.7.0bx Nov 24th, 2003 JMM gCurrentVMEncoding
	3.8.7bx Mar 24th, 2005 JMM Add feature to convert from posix to HFS+
	3.8.9b8 Jan 8th, 2006 JMM rework ioFilenamefromStringofLengthresolveAliases and makeosxpath
*
*****************************************************************************/
/* 
In a few places the VM needs an FSSpec.
Given a path we need to create an FSSPec. Why? Well some  mac routines still need 
FSSPecs to work, ie resolve alias. HFS+ will have funny formed names if the name is > 32 chars 

Also given an FSSpec we need to get a path name back. 

Someday this might become all FSRef aware

Note that Squeak thinks of things in terms of HFS path names, but here sometimes we think 
in terms of POSIX path names.

Just to complicate things CW Pro likes to think of names in terms of HFS path names for unix calls.
Also if you attempt to use Apple's StdClib it wants posix names, sigh...
*/
#if TARGET_API_MAC_CARBON
	#include <Carbon/Carbon.h>
#else
	#include <AppleEvents.h>
	EXTERN_API( OSErr ) AEGetDescData(
  const AEDesc *  theAEDesc,
  void *          dataPtr,
  Size            maximumSize);

#endif

#include "sq.h"
#include "sqVirtualMachine.h"
#include "sqMacUnixFileInterface.h"	

static void resolveLongName(short vRefNum, long parID, unsigned char *shortFileName,FSSpec *possibleSpec,Boolean isFolder,Str255 *name,squeakFileOffsetType *sizeOfFile);
static int fetchFileSpec(FSSpec *spec,unsigned char *name,long *parentDirectory);
static int quicklyMakePath(char *pathString, int pathStringLength, char *dst, Boolean resolveAlias);
extern int  IsImageName(char *name);
extern Boolean isSystem9_0_or_better(void);

#if TARGET_API_MAC_CARBON
void unicode2NativePascalString(ConstStr255Param fromString, StringPtr toString) ;

OSErr makeFSSpec(char *pathString, int pathStringLength,FSSpec *spec)
{	
    CFURLRef    sillyThing;
    CFStringRef tmpStrRef;
	CFMutableStringRef filePath;
    FSRef	theFSRef;
    OSErr	err;
    
    tmpStrRef = CFStringCreateWithBytes(kCFAllocatorDefault,(UInt8 *) pathString,
										pathStringLength, gCurrentVMEncoding, true);
    if (tmpStrRef == nil)
        return -1000;
	filePath = CFStringCreateMutableCopy(NULL, 0, tmpStrRef);
	if (gCurrentVMEncoding == kCFStringEncodingUTF8) 
		CFStringNormalize(filePath, kCFStringNormalizationFormD);
    sillyThing = CFURLCreateWithFileSystemPath (kCFAllocatorDefault,filePath,kCFURLHFSPathStyle,false);
	if (sillyThing == NULL) 
		return -2000;
		
    if (CFURLGetFSRef(sillyThing,&theFSRef) == false) {
        // name contains multiple aliases or does not exist, so fallback to lookupPath
        CFRelease(filePath);
        CFRelease(sillyThing);
        return lookupPath(pathString,pathStringLength,spec,true,true);
    } 
            
    CFRelease(filePath);
    err = FSGetCatalogInfo (&theFSRef,kFSCatInfoNone,nil,nil,spec,nil);
    CFRelease(sillyThing);
    return err;
}

/* Fill in the given string with the full path from a root volume to the given directory. */

int PathToDir(char *pathName, int pathNameMax, FSSpec *where,UInt32 encoding) {
    CopyCStringToPascal(":",where->name);
	return PathToFile(pathName,pathNameMax,where,encoding);  
}

/* Fill in the given string with the full path from a root volume to the given file. */
/* From FSSpec to C-string pathName */
/* FSSpec -> FSRef -> URL(Unix) -> HPFS+ */
int PathToFile(char *pathName, int pathNameMax, FSSpec *where,UInt32 encoding) {        
        CFURLRef sillyThing;
        CFStringRef filePath;
        FSSpec	failureRetry;
        FSRef	theFSRef;
        OSErr	error;
        Boolean isDirectory=false,retryWithDirectory=false;
        char	rememberName[256];
        
        *pathName = 0x00;
        error = FSpMakeFSRef (where, &theFSRef);
        if (error != noErr) {
            retryWithDirectory = true;
            failureRetry = *where;
            CopyCStringToPascal(":",failureRetry.name);
            CopyPascalStringToC(where->name,(char *) &rememberName);
            error = FSpMakeFSRef(&failureRetry,&theFSRef);
            if (error != noErr) 
                return -1;
	}
        
        sillyThing =  CFURLCreateFromFSRef (kCFAllocatorDefault, &theFSRef);
        isDirectory = CFURLHasDirectoryPath(sillyThing);
        
        filePath = CFURLCopyFileSystemPath (sillyThing, kCFURLHFSPathStyle);
        CFRelease(sillyThing);
        
  		CFMutableStringRef mutableStr= CFStringCreateMutableCopy(NULL, 0, filePath);
          CFRelease(filePath);
  
  		// HFS+ imposes Unicode2.1 decomposed UTF-8 encoding on all path elements
  		if (gCurrentVMEncoding == kCFStringEncodingUTF8) 
  			CFStringNormalize(mutableStr, kCFStringNormalizationFormKC); // pre-combined
  
          CFStringGetCString (mutableStr, pathName,pathNameMax, encoding);
        
        if (retryWithDirectory) {
            strcat(pathName,":");
            strcat(pathName,rememberName);
            isDirectory = false;
        }
        if (isDirectory)
            strcat(pathName,":");
        return 0;
}

static int quicklyMakePath(char *pathString, int pathStringLength,char *dst, Boolean resolveAlias) {
	CFStringRef 	filePath;
        CFURLRef 	sillyThing,firstPartOfPath;
        FSRef		theFSRef;   
        Boolean		isFolder,isAlias;
        OSErr		err;
        
        filePath   = CFStringCreateWithBytes(kCFAllocatorDefault,
                    (UInt8 *)pathString,pathStringLength,gCurrentVMEncoding,false);
        if (filePath == nil)
            return -1;
		CFMutableStringRef str= CFStringCreateMutableCopy(NULL, 0, filePath);
		// HFS+ imposes Unicode2.1 decomposed UTF-8 encoding on all path elements
		if (gCurrentVMEncoding == kCFStringEncodingUTF8) 
			CFStringNormalize(str, kCFStringNormalizationFormKC); // canonical decomposition

		sillyThing = CFURLCreateWithFileSystemPath (kCFAllocatorDefault, str, kCFURLHFSPathStyle,false);
		if (sillyThing == NULL) {
			CFRelease(filePath);
			return -2;
		}
		CFRelease(str);
        
        if (!CFURLGetFSRef(sillyThing,&theFSRef)) {
            firstPartOfPath = CFURLCreateCopyDeletingLastPathComponent(kCFAllocatorDefault,sillyThing);
            if (!CFURLGetFSRef(firstPartOfPath,&theFSRef)) {
                CFRelease(firstPartOfPath);
                CFRelease(filePath);
                CFRelease(sillyThing);
                return -1;
            } else {
                CFStringRef lastPathPart;
                char	 lastpart[256];
                
                CFRelease(filePath);
                CFRelease(firstPartOfPath);
                lastPathPart = CFURLCopyLastPathComponent(sillyThing);
                CFRelease(sillyThing);
                
                err = noErr;
                if (resolveAlias) 
                    err = FSResolveAliasFile (&theFSRef,true,&isFolder,&isAlias);

                if (err) 
                    return 2;
                
                err = FSRefMakePath(&theFSRef,(UInt8 *)dst,1000); 
                CFStringGetCString(lastPathPart,lastpart,256, kCFStringEncodingUTF8);
                CFRelease(lastPathPart);
                if (strlen(dst)+1+strlen(lastpart) < 1000) {
                    strcat(dst,"/");
                    strcat(dst,lastpart);
                    
#if defined(__MWERKS__) && !defined(__APPLE__) && !defined(__MACH__)
        filePath   = CFStringCreateWithBytes(kCFAllocatorDefault,(UInt8 *)dst,strlen(dst),gCurrentVMEncoding,false);
        if (filePath == nil) 
            return 2;
        sillyThing = CFURLCreateWithFileSystemPath (kCFAllocatorDefault,filePath,kCFURLPOSIXPathStyle,true);
		CFRelease(filePath);
        filePath = CFURLCopyFileSystemPath (sillyThing, kCFURLHFSPathStyle);
        CFStringGetCString (filePath,dst,1000, gCurrentVMEncoding);
		CFRelease(sillyThing);
        CFRelease(filePath);        
#endif

                    return 0;
                } else
                    return 2;
            }
        }
        
        CFRelease(filePath);
        CFRelease(sillyThing);
        
        if (resolveAlias) 
            err = FSResolveAliasFile (&theFSRef,true,&isFolder,&isAlias);

#if defined(__MWERKS__) && !defined(__APPLE__) && !defined(__MACH__)
		sillyThing = CFURLCreateFromFSRef(kCFAllocatorDefault,&theFSRef);
        filePath = CFURLCopyFileSystemPath (sillyThing, kCFURLHFSPathStyle);
        CFStringGetCString (filePath,dst,1000, gCurrentVMEncoding);
		CFRelease(sillyThing);
        CFRelease(filePath);        
        return 0;
#else
        err = FSRefMakePath(&theFSRef,(UInt8 *)dst,1000); 
        return err;
#endif 
}

/* Some classcical Mac APIs use the encoding based on WorldScript. for example, Japanese language envrironment use
ShiftJIS encoding. So, unicode2NativePascalString, this function converts unicode encoded pascal string to suitable
encoding (came from CFStringGetSystemEncoding()).
*/
void unicode2NativePascalString(ConstStr255Param fromString, StringPtr toString) {
	if (fromString != NULL) {
		CFStringRef strRef = CFStringCreateWithPascalString(kCFAllocatorDefault, fromString, gCurrentVMEncoding);
		if (strRef != NULL) {
			CFMutableStringRef mStrRef = CFStringCreateMutableCopy(NULL, 0, strRef);
			if (gCurrentVMEncoding == kCFStringEncodingUTF8) 
				CFStringNormalize(mStrRef, kCFStringNormalizationFormKD);
			CFStringGetPascalString (mStrRef, toString, 256, CFStringGetSystemEncoding());
			CFRelease(mStrRef);
			CFRelease(strRef);
		}
	}
}

/* Convert the squeak path to an OS-X path. This path because of alias resolving may point 
to another directory tree */

void		sqFilenameFromStringOpen(char *buffer,long fileIndex, long fileLength) {
	ioFilenamefromStringofLengthresolveAliases(buffer,(char *) fileIndex, fileLength, true);
}

void		sqFilenameFromString(char *buffer,long fileIndex, long fileLength) {
	ioFilenamefromStringofLengthresolveAliases(buffer,(char *) fileIndex, fileLength, false);
}

sqInt	ioFilenamefromStringofLengthresolveAliases(char* dst, char* src, sqInt num, sqInt resolveAlias) {
        FSRef		theFSRef;
        FSSpec		convertFileNameSpec,failureRetry;
        OSErr		err;
        Boolean		isFolder=false,isAlias=false;
        CFURLRef 	sillyThing,appendedSillyThing;
        CFStringRef 	lastPartOfPath,filePath2;
		CFMutableStringRef filePath;
        
        *dst = 0x00;
        err = quicklyMakePath((char *) src,num,dst,resolveAlias);
        if (err == noErr) 
            return;
            
        err = lookupPath((char *) src,num,&convertFileNameSpec,true,false);
        if ((err == noErr) && resolveAlias) {
            err = ResolveAliasFile(&convertFileNameSpec,true,&isFolder,&isAlias);
            if (err == fnfErr) {
				err = lookupPath((char *) src,num,&convertFileNameSpec,false,false);
	            err = ResolveAliasFile(&convertFileNameSpec,true,&isFolder,&isAlias);
            }
        }
        
        if (err == fnfErr) {
            failureRetry = convertFileNameSpec;
            CopyCStringToPascal("::",failureRetry.name);
            err = FSpMakeFSRef(&failureRetry,&theFSRef);
            if (err != noErr) 
                return;
//            filePath   = CFStringCreateWithBytes(kCFAllocatorDefault,(UInt8 *)src,num,gCurrentVMEncoding,false);
			CFStringRef tmpStrRef = CFStringCreateWithBytes(kCFAllocatorDefault,(UInt8 *)src,num,gCurrentVMEncoding,false);
            if (tmpStrRef == nil) 
                return;
			filePath = CFStringCreateMutableCopy(NULL, 0, tmpStrRef);
			if (gCurrentVMEncoding == kCFStringEncodingUTF8) 
				CFStringNormalize(filePath, kCFStringNormalizationFormKD); // canonical decomposition

            sillyThing = CFURLCreateWithFileSystemPath (kCFAllocatorDefault,filePath,kCFURLHFSPathStyle,false);
            CFRelease(filePath);
			if (sillyThing == NULL) 
					return;

            lastPartOfPath = CFURLCopyLastPathComponent(sillyThing);
            CFRelease(sillyThing);
            sillyThing = CFURLCreateFromFSRef(kCFAllocatorDefault,&theFSRef);
            appendedSillyThing = CFURLCreateCopyAppendingPathComponent(kCFAllocatorDefault,sillyThing,lastPartOfPath,false);
#if defined(__MWERKS__) && !defined(__APPLE__) && !defined(__MACH__)
            filePath2 = CFURLCopyFileSystemPath (appendedSillyThing, kCFURLHFSPathStyle);
#else
            filePath2 = CFURLCopyFileSystemPath (appendedSillyThing, kCFURLPOSIXPathStyle);
#endif
            CFStringGetCString (filePath2,dst,1000, gCurrentVMEncoding);
            CFRelease(sillyThing);
            CFRelease(appendedSillyThing);
            CFRelease(lastPartOfPath);
            CFRelease(filePath2);        
            return; 
        }
        	
        err = FSpMakeFSRef(&convertFileNameSpec,&theFSRef);
#if defined(__MWERKS__) && !defined(__APPLE__) && !defined(__MACH__)
		sillyThing = CFURLCreateFromFSRef(kCFAllocatorDefault,&theFSRef);
        filePath = CFURLCopyFileSystemPath (sillyThing, kCFURLHFSPathStyle);
        CFStringGetCString (filePath,dst,1000, gCurrentVMEncoding);
		CFRelease(sillyThing);
        CFRelease(filePath);        
        return;
 #else
        err = FSRefMakePath(&theFSRef,(UInt8 *)dst,1000); 
 #endif
}

int makeHFSFromPosixPath(char *pathString, int pathStringLength,char *dst,char *lastpart) {
		CFStringRef filePath;
        CFURLRef 	sillyThing;
        CFStringRef	filePath2,lastPathPart;
		
        dst[0] = 0x00;
		if (lastpart)
			lastpart[0] = 0x00;
		filePath   = CFStringCreateWithBytes(kCFAllocatorDefault,
                    (UInt8 *)pathString,pathStringLength,gCurrentVMEncoding,false);
        if (filePath == nil)
            return -1;
			
		// HFS+ imposes Unicode2.1 decomposed UTF-8 encoding on all path elements
		CFMutableStringRef str= CFStringCreateMutableCopy(NULL, 0, filePath);
		if (gCurrentVMEncoding == kCFStringEncodingUTF8) 
			CFStringNormalize(str, kCFStringNormalizationFormKC); // canonical decomposition

		sillyThing = CFURLCreateWithFileSystemPath (kCFAllocatorDefault, str, kCFURLPOSIXPathStyle,false);
		CFRelease(str);
		if (sillyThing == NULL) 
			return -2;
		
		filePath2 = CFURLCopyFileSystemPath (sillyThing, kCFURLHFSPathStyle);
		CFStringGetCString (filePath2,dst,1000, gCurrentVMEncoding);
		if (lastpart) {
			lastPathPart = CFURLCopyLastPathComponent(sillyThing);
			CFStringGetCString(lastPathPart,lastpart,256, gCurrentVMEncoding);
			CFRelease(lastPathPart);
		}
        CFRelease(filePath);
        CFRelease(sillyThing);
        CFRelease(filePath2);
        return 0;
}

/* This method is used to lookup paths, chunk by chunk. It builds specs for each chunk and fetchs the file 
information, Note the special case when noDrilldown */

int doItTheHardWay(unsigned char *pathString,FSSpec *spec,Boolean noDrillDown) {
    char *token;
    Str255 lookup;
    UniChar   buffer[1024];
    Boolean firstTime=true;
    OSErr   err;
    long    parentDirectory,tokenLength;
    FSRef   parentFSRef,childFSRef;
    CFStringRef aLevel;
    FSSpec	fix;
    
    token = strtok((char*) pathString,":");
    if (token == 0) return -1;
    while (token) 
    {
        tokenLength = strlen(token);
        if (firstTime) {// Mmm will crash if volume name is 255 characters, unlikely
            strncpy((char*) lookup+1,(char*) token,tokenLength);
            lookup[0] = tokenLength+1;
            lookup[lookup[0]] = ':';
            firstTime = false;
            err = FSMakeFSSpecCompat(spec->vRefNum,spec->parID, lookup, spec);
            if (err != noErr)
                return err;
            err = FSpMakeFSRef(spec,&parentFSRef);
            if (err != noErr)
                return err;
        } else {
            fix = *spec;
            fix.name[0] = 0;
            err = FSpMakeFSRef(&fix,&parentFSRef);
            if (err != noErr)
                return err;
           aLevel = CFStringCreateWithCString(kCFAllocatorDefault,token,gCurrentVMEncoding);
           if (aLevel == nil) 
                return -1000;
           tokenLength = CFStringGetLength(aLevel);
           CFStringGetCharacters(aLevel,CFRangeMake(0,tokenLength),buffer);
           err = FSMakeFSRefUnicode(&parentFSRef,tokenLength,buffer,gCurrentVMEncoding,&childFSRef);
           if (err != noErr) {
                CFStringGetPascalString(aLevel,spec->name,64,gCurrentVMEncoding);
                CFRelease(aLevel);
				token = strtok(nil,":"); 
				if (token == nil)
					return err;
				else
					return -1001;
            }
           CFRelease(aLevel);
           parentFSRef = childFSRef;
           err = FSGetCatalogInfo (&parentFSRef,kFSCatInfoNone,nil,nil,spec,nil);
            if (err != noErr)
                return err;
        }
        fetchFileSpec(spec,spec->name,&parentDirectory);
        token = strtok(nil,":"); 
    }
   if (noDrillDown) 
       spec->parID = parentDirectory;
     return noErr;
}



#else
/* OS 8 and pre carbon logic */
static OSErr FSpGetFullPath(const FSSpec *spec, short *fullPathLength, Handle *fullPath);

static OSErr	FSpGetFullPath(const FSSpec *spec,
							   short *fullPathLength,
							   Handle *fullPath)
{
	OSErr		result;
	OSErr		realResult;
	FSSpec		tempSpec;
	CInfoPBRec	pb;
	
	*fullPathLength = 0;
	*fullPath = nil;
	
	
	/* Default to noErr */
	realResult = result = noErr;
	
	result = FSMakeFSSpecCompat(spec->vRefNum, spec->parID, spec->name, &tempSpec);

	if ( result == noErr )
	{
		if ( tempSpec.parID == fsRtParID )
		{
			/* The object is a volume */
			
			/* Add a colon to make it a full pathname */
			++tempSpec.name[0];
			tempSpec.name[tempSpec.name[0]] = ':';
			
			/* We're done */
			result = PtrToHand(&tempSpec.name[1], fullPath, tempSpec.name[0]);
			*fullPathLength = tempSpec.name[0];
		}
		else
		{
			/* The object isn't a volume */
			
			/* Is the object a file or a directory? */
			pb.dirInfo.ioNamePtr = tempSpec.name;
			pb.dirInfo.ioVRefNum = tempSpec.vRefNum;
			pb.dirInfo.ioDrDirID = tempSpec.parID;
			pb.dirInfo.ioFDirIndex = 0;
			result = PBGetCatInfoSync(&pb);
			// Allow file/directory name at end of path to not exist.
			realResult = result;
			if ( (result == noErr) || (result == fnfErr) )
			{
				/* if the object is a directory, append a colon so full pathname ends with colon */
				if ( (result == noErr) && (pb.hFileInfo.ioFlAttrib & kioFlAttribDirMask) != 0 )
				{
					++tempSpec.name[0];
					tempSpec.name[tempSpec.name[0]] = ':';
				}
				
				/* Put the object name in first */
				result = PtrToHand(&tempSpec.name[1], fullPath, tempSpec.name[0]);
				*fullPathLength = tempSpec.name[0];
				if ( result == noErr )
				{
					/* Get the ancestor directory names */
					pb.dirInfo.ioNamePtr = tempSpec.name;
					pb.dirInfo.ioVRefNum = tempSpec.vRefNum;
					pb.dirInfo.ioDrParID = tempSpec.parID;
					do	/* loop until we have an error or find the root directory */
					{
						pb.dirInfo.ioFDirIndex = -1;
						pb.dirInfo.ioDrDirID = pb.dirInfo.ioDrParID;
						result = PBGetCatInfoSync(&pb);
						if ( result == noErr )
						{
							/* Append colon to directory name */
							++tempSpec.name[0];
							tempSpec.name[tempSpec.name[0]] = ':';
							
							/* Add directory name to beginning of fullPath */
							(void) Munger(*fullPath, 0, nil, 0, &tempSpec.name[1], tempSpec.name[0]);
							*fullPathLength += tempSpec.name[0];
							result = MemError();
						}
					} while ( (result == noErr) && (pb.dirInfo.ioDrDirID != fsRtDirID) );
				}
			}
		}
	}
	
	if ( result == noErr )
	{
		/* Return the length */
///		*fullPathLength = GetHandleSize(*fullPath);
		result = realResult;	// return realResult in case it was fnfErr
	}
	else
	{
		/* Dispose of the handle and return nil and zero length */
		if ( *fullPath != nil )
		{
			DisposeHandle(*fullPath);
		}
		*fullPath = nil;
		*fullPathLength = 0;
	}
	
	return ( result );
}



int PathToDir(char *pathName, int pathNameMax, FSSpec *where,UInt32 encoding) {
	/* Fill in the given string with the full path from a root volume to
	   to given  directory.
	*/
        CopyCStringToPascal(":",where->name);
	return PathToFile(pathName,pathNameMax,where,encoding);  
}

int PathToFile(char *pathName, int pathNameMax, FSSpec *where,UInt32 encoding) {
        OSErr	error;
        short 	pathLength;
        Handle fullPathHandle;
#pragma unused(encoding)
        
	error =  FSpGetFullPath(where, &pathLength, &fullPathHandle);
	if (fullPathHandle != 0) {
            pathLength = pathLength+1 > pathNameMax ? pathNameMax-1 : pathLength;
            strncpy((char *) pathName, (char *) *fullPathHandle, pathLength);
            pathName[pathLength] = 0x00;
            DisposeHandle(fullPathHandle);
        } else {
            *pathName = 0x00;
            pathLength = 0;
        }
	return pathLength;
}


OSErr makeFSSpec(char *pathString, int pathStringLength,FSSpec *spec)
{	
	char name[1001];
	
	if (pathStringLength > 1000 ) 
	    return -1;
   
    strncpy((char *) name,pathString,pathStringLength);
    name[pathStringLength] = 0x00;
    return __path2fss((char *) name, spec);
}


/* This method is used to lookup paths, chunk by chunk. It builds specs for each chunk and fetchs the file 
information, Note the special case when noDrilldown */

int doItTheHardWay(unsigned char *pathString,FSSpec *spec,Boolean noDrillDown) {
    char *token;
    Str255 lookup;
    Boolean firstTime=true;
    OSErr   err;
    long    parentDirectory,tokenLength;
    
    token = strtok((char*) pathString,":");
    if (token == 0) return -1;
    while (token) 
    {
        tokenLength = strlen(token) > 255 ? 255 : strlen(token);
        if (firstTime) {
            strncpy((char*) lookup+1,(char*) token,tokenLength);
            lookup[0] = tokenLength+1;
            lookup[lookup[0]] = ':';
            firstTime = false;
        } else {
            if (tokenLength == 255) { /* This is broken */
                FSSpec spec2;
                strncpy((char*) lookup+1,(char*) token,tokenLength);
                lookup[0] = tokenLength;
                if ((err = FSMakeFSSpecCompat(spec->vRefNum,spec->parID, lookup, &spec2)) != noErr) 
                    return err;               
            } else {
            strncpy((char*) lookup+2,(char*) token,tokenLength);
            lookup[0] = tokenLength+1;
            lookup[1] = ':';
            }
        }
        if ((err = FSMakeFSSpecCompat(spec->vRefNum,spec->parID, lookup, spec)) != noErr) 
            return err;
        fetchFileSpec(spec,spec->name,&parentDirectory);
        token = strtok(nil,":"); 
    }
   if (noDrillDown) 
       spec->parID = parentDirectory;
     return noErr;
}		 
#endif

/*
JMM 2001/02/02 rewrote 
These are common routines

*/

int lookupPath(char *pathString, int pathStringLength, FSSpec *spec,Boolean noDrillDown,Boolean tryShortCut) {
	/* Resolve the given path and return the resulting folder or volume
	   reference number in *refNumPtr. Return error if the path is bad. */

	char          	tempName[1001];
 	OSErr		    err;
 	int		        i;
 	
    if (pathStringLength < 256 && tryShortCut) {
        /* First locate by farily normal methods, with perhaps an alias lookup */
 		tempName[0] = pathStringLength;
		strncpy((char *)tempName+1,pathString,pathStringLength);
    
        err = FSMakeFSSpecCompat(0,0,(unsigned char*) tempName,spec);
    
        if (err == noErr) {
            if (noDrillDown == false) {
                fetchFileSpec(spec,spec->name,nil);
            }
            return noErr;
        }         
    }
    /* Than failed, we might have an alias chain, or other issue so 
    first setup for directory or file then do it the hard way */
    
    strncpy((char *)tempName,pathString,pathStringLength);
    if (noDrillDown) {
        tempName[pathStringLength] = 0x00;
    }
    else {
        tempName[pathStringLength] = ':';
        tempName[pathStringLength+1] = 0x00;
    }

  	i = 0;
  	while(tempName[i]) {
   		if(tempName[i] == ':') {
      		if(tempName[i+1] == ':')
				return fnfErr; /* fix for :: doItTheHardWay can't deal with this */
   		 }
   		i++;
    }

    err = doItTheHardWay((unsigned char*) tempName,spec,noDrillDown);
    return err;
}


/*Get the file ID that unique IDs this file or directory, also resolve any alias if required */
int fetchFileInfo(int dirIndex,FSSpec *spec,unsigned char *name,Boolean doAlias,long *parentDirectory,
 int *isFolder,int *createDateStorage,int *modificationDateStorage,squeakFileOffsetType *sizeOfFile,Str255 *longFileName) {
    long        aliasGestaltInfo;
    CInfoPBRec pb;
    Boolean     isFolder2;
    OSErr	error,result;
    
    *isFolder = false;
        
    pb.hFileInfo.ioNamePtr = name;
    pb.hFileInfo.ioFVersNum = 0;
    pb.hFileInfo.ioFDirIndex = dirIndex;
    pb.hFileInfo.ioVRefNum = spec->vRefNum;
    pb.hFileInfo.ioDirID = spec->parID;

    if ((error = PBGetCatInfoSync(&pb)) == noErr) {
    	if ((pb.hFileInfo.ioFlFndrInfo.fdFlags & kIsAlias) && doAlias) {
		    FSSpec spec2,spec3;
		    Boolean isAlias;
		    OSErr   err;
		    
		   
		   err = FSMakeFSSpecCompat(spec->vRefNum, spec->parID, name,&spec2);
           spec3 = spec2;
#if TARGET_CPU_PPC
           if ((Gestalt(gestaltAliasMgrAttr, &aliasGestaltInfo) == noErr) &&
                aliasGestaltInfo & (1<<gestaltAliasMgrResolveAliasFileWithMountOptions)  &&
                ((Ptr) ResolveAliasFileWithMountFlags != (Ptr)kUnresolvedCFragSymbolAddress)) {
                err = ResolveAliasFileWithMountFlags(&spec2,false,&isFolder2,&isAlias,kResolveAliasFileNoUI);
            } else {
                err = ResolveAliasFile(&spec2,false,&isFolder2,&isAlias);
            }
#else
			err = ResolveAliasFile(&spec2,false,&isFolder2,&isAlias);
#endif         
			*isFolder = isFolder2;
            if (err == noErr) {
                resolveLongName(0,0,nil,&spec3,*isFolder,longFileName,sizeOfFile);
                result = noErr;
                goto done;
		    }
    	}
    	
    	if ((pb.hFileInfo.ioFlAttrib & kioFlAttribDirMask) != 0)
    	    *sizeOfFile = 0;
    	else
            *sizeOfFile =  pb.hFileInfo.ioFlLgLen;
            
        resolveLongName(pb.hFileInfo.ioVRefNum,pb.hFileInfo.ioFlParID,name,nil,((pb.hFileInfo.ioFlAttrib & kioFlAttribDirMask) > 0),longFileName,sizeOfFile);
        spec->parID = pb.hFileInfo.ioDirID;
        result = noErr;
        goto done;
    }
    result = error;
    memcpy(longFileName,name,sizeof(StrFileName));
    
    done:
    *isFolder = ((pb.hFileInfo.ioFlAttrib & kioFlAttribDirMask) > 0) || *isFolder;
    *createDateStorage =  pb.hFileInfo.ioFlCrDat;
    *modificationDateStorage =  pb.hFileInfo.ioFlMdDat;
    *parentDirectory = pb.dirInfo.ioDrParID;
    return result;
}

static int fetchFileSpec(FSSpec *spec,unsigned char *name,long *parentDirectory) {
    long        aliasGestaltInfo;
    CInfoPBRec  pb;
    Boolean     result,ignore;
    FSSpec      spec2;
    OSErr       err;
        
    pb.hFileInfo.ioNamePtr = name;
    pb.hFileInfo.ioFVersNum = 0;
    pb.hFileInfo.ioFDirIndex = 0;
    pb.hFileInfo.ioVRefNum = spec->vRefNum;
    pb.hFileInfo.ioDirID = spec->parID;

    if (PBGetCatInfoSync(&pb) == noErr) {
    	if (pb.hFileInfo.ioFlFndrInfo.fdFlags & kIsAlias) {     	   
    	   err = FSMakeFSSpecCompat(spec->vRefNum, spec->parID, name,&spec2);
    #if TARGET_CPU_PPC
           if ((Gestalt(gestaltAliasMgrAttr, &aliasGestaltInfo) == noErr) &&
                aliasGestaltInfo & (1<<gestaltAliasMgrResolveAliasFileWithMountOptions)  &&
                ((Ptr) ResolveAliasFileWithMountFlags != (Ptr)kUnresolvedCFragSymbolAddress)) {
                err = ResolveAliasFileWithMountFlags(&spec2,false,&ignore,&ignore,kResolveAliasFileNoUI);
            } 
            else 
    #endif
    			err = ResolveAliasFile(&spec2,false,&ignore,&ignore);
                if (err == noErr) {
             	    fetchFileSpec(&spec2,spec2.name,parentDirectory);
            	    *spec = spec2;
                    result = true;
                    goto done;
    		    }
    	}
        spec->parID = pb.hFileInfo.ioDirID;
        result = true;
        goto done;
    }
    result = false;
    
    done:
        if (parentDirectory != nil)
            *parentDirectory = pb.dirInfo.ioDrParID;
        return result;
}

static void resolveLongName(short vRefNum, long parID,unsigned char*shortFileName,FSSpec *possibleSpec,Boolean isFolder,Str255 *name,squeakFileOffsetType *sizeOfFile) {
    
#if TARGET_API_MAC_CARBON 
    if ((Ptr) PBGetCatalogInfoSync != (Ptr)kUnresolvedCFragSymbolAddress) {
        FSRefParam FSRefData;
        FSRef      theFSRef;
        FSCatalogInfo theCatalogInfo;
        HFSUniStr255 	unicodeName;
        OSErr     err;

        if (possibleSpec == nil) {
            FSRefParam FSParam;
            
            FSParam.ioNamePtr = shortFileName;
            FSParam.ioVRefNum = vRefNum;
            FSParam.ioDirID = parID;
            FSParam.newRef = &theFSRef;
            FSParam.ioCompletion = null;

            err = PBMakeFSRefSync(&FSParam);

            if (err != noErr)
                goto done1;   
        } else {
            err = FSpMakeFSRef(possibleSpec,&theFSRef);
            if (err != noErr)
             goto done1;   
        }
                
        FSRefData.ref = &theFSRef;
        FSRefData.whichInfo = kFSCatInfoDataSizes;
        FSRefData.catInfo = &theCatalogInfo;
        FSRefData.spec = nil;
        FSRefData.parentRef = nil;
        FSRefData.outName = &unicodeName;
        
        if (PBGetCatalogInfoSync(&FSRefData) == noErr) {
           CFStringRef 	theString;
           
            if (isFolder) 
                *sizeOfFile = 0;
            else
                *sizeOfFile =  theCatalogInfo.dataLogicalSize; 
                
           theString = CFStringCreateWithCharacters (kCFAllocatorDefault, unicodeName.unicode, (CFIndex) unicodeName.length);
			CFMutableStringRef mStr= CFStringCreateMutableCopy(NULL, 0, theString);
           CFRelease(theString);
			// HFS+ imposes Unicode2.1 decomposed UTF-8 encoding on all path elements
			if (gCurrentVMEncoding == kCFStringEncodingUTF8) 
				CFStringNormalize(mStr, kCFStringNormalizationFormKC); // canonical decomposition

           CFStringGetPascalString(mStr, (unsigned char *) name,256, gCurrentVMEncoding);
           CFRelease(mStr);
           return;
        }
   }
   done1:
   memcpy(name,shortFileName,sizeof(StrFileName));
#else
   if (shortFileName == nil)
   	  memcpy(name,possibleSpec->name,sizeof(StrFileName));
   else
   	  memcpy(name,shortFileName,sizeof(StrFileName));
#endif
}

#if defined(__MWERKS__)
int RunningOnCarbonX();
OSErr __path2fss(const char * pathName, FSSpecPtr spec);

OSErr __path2fss(const char * pathName, FSSpecPtr spec) {
    return lookupPath((char *) pathName, strlen(pathName),spec,true,true);
}
#endif


Boolean isVmPathVolumeHFSPlus() {
    XVolumeParam        xpb;
    OSErr               err;
    static int 		cachedCheck = -1;
    
    if (cachedCheck != -1) 
        return cachedCheck;
        
    xpb.ioNamePtr   = NULL;
    xpb.ioVRefNum   = 0;
    xpb.ioXVersion  = 0;
    xpb.ioVolIndex  = 0;

    err = PBXGetVolInfoSync( &xpb );
    if (err != noErr)  
    	cachedCheck = false;
    else
        cachedCheck = xpb.ioVSigWord == kHFSPlusSigWord;
    return cachedCheck;
}

OSErr	FSMakeFSSpecCompat(short vRefNum, long dirID, ConstStr255Param fileName,  FSSpec *spec) {
	OSErr	result;
#if TARGET_API_MAC_CARBON
	char pascalString[256];
#endif	
	/* Let the file system create the FSSpec if it can since it does the job */
	/* much more efficiently than I can. */
#if TARGET_API_MAC_CARBON
	unicode2NativePascalString((unsigned char *) fileName, (unsigned char *) pascalString);	
	result = FSMakeFSSpec(vRefNum, dirID,(unsigned char *) pascalString, spec);
#else
	result = FSMakeFSSpec(vRefNum, dirID,(unsigned char *) fileName, spec);
#endif
	/* Fix a bug in Macintosh PC Exchange's MakeFSSpec code where 0 is */
	/* returned in the parID field when making an FSSpec to the volume's */
	/* root directory by passing a full pathname in MakeFSSpec's */
	/* fileName parameter. Fixed in Mac OS 8.1 */
	if ( (result == noErr) && (spec->parID == 0) )
		spec->parID = fsRtParID;
	return ( result );
}

/*****************************************************************************************
GetApplicationDirectory

Get the volume reference number and directory id of this application.
Code taken from Apple:
	Technical Q&As: FL 14 - Finding your application's directory (19-June-2000)

Karl Goiser 14/01/01
*****************************************************************************************/

        /* GetApplicationDirectory returns the volume reference number
        and directory ID for the current application's directory. */

OSStatus GetApplicationDirectory(FSSpec *workingDirectory) {
        ProcessSerialNumber PSN;
        ProcessInfoRec pinfo;
        OSErr	err;
        
                  /* set up process serial number */
        PSN.highLongOfPSN = 0;
        PSN.lowLongOfPSN = kCurrentProcess;
            /* set up info block */
        pinfo.processInfoLength = sizeof(pinfo);
        pinfo.processName = 0;
        pinfo.processAppSpec = workingDirectory;
        err = GetProcessInformation(&PSN, &pinfo);
        if (err == noErr && isSystem9_0_or_better()) {
#if TARGET_API_MAC_CARBON && !defined(__MWERKS__)
			FSMakeFSSpecCompat(workingDirectory->vRefNum, workingDirectory->parID,"\p:::",workingDirectory);
#else
			FSSpec	checkDirectory;
            FSMakeFSSpecCompat(workingDirectory->vRefNum, workingDirectory->parID,"\p:",&checkDirectory);
            if (strncmp((const char *)checkDirectory.name,(const char *) "\pMacOSClassic",13) == 0)
				FSMakeFSSpecCompat(workingDirectory->vRefNum, workingDirectory->parID,"\p:::",workingDirectory);
#endif
        }
        return err;
}

#if defined(__MWERKS__) && !defined(__APPLE__) && !defined(__MACH__)
typedef struct {
	StandardFileReply *theSFR;
	FSSpec *itemSpec;
} HookRecord, *HookRecordPtr;
#endif

OSErr squeakFindImage(const FSSpecPtr defaultLocationfssPtr,FSSpecPtr documentFSSpec)
{
    NavDialogOptions    dialogOptions;
    AEDesc              defaultLocation;
    NavEventUPP         eventProc = NewNavEventUPP(findImageEventProc);
    NavObjectFilterUPP  filterProc =  NewNavObjectFilterUPP(findImageFilterProc);
    OSErr               anErr = noErr;
    
#if !TARGET_API_MAC_CARBON 
#if   MINIMALVM
  if (true) {
#else
  if ((Ptr) NavGetDefaultDialogOptions==(Ptr)kUnresolvedCFragSymbolAddress ) {
#endif
      	//System pre 8.5 or system 7.x
    	// point my hook data record at the reply record and at
		// the file spec for the system file
		
     	StandardFileReply mySFR;
#if defined(__MWERKS__) && !defined(__APPLE__) && !defined(__MACH__)
    	HookRecord hookRec;
#endif

        DlgHookYDUPP	myDlgHookUPP;
    	SFTypeList mySFTypeList;
	    Point dialogPt;
	    
		hookRec.itemSpec = defaultLocationfssPtr;
		hookRec.theSFR = &mySFR;
		SetPt(&dialogPt, -1, -1);

		// Set up the universal proc pointer to your hook routine with this 
		// macro defined in StandardFile.h.  **NOTE** This is different
		// from the macro used for System 6 dialog hooks, and you should get
		// a compiler error if you try to use the wrong UPP with the wrong call.
		myDlgHookUPP = NewDlgHookYDProc(DialogHook);
		
		// call Std File
		CustomGetFile(nil, -1, mySFTypeList, &mySFR, 0, dialogPt, myDlgHookUPP,
			nil, nil, nil, &hookRec);
			
		// Dispose of the routine descriptor, since they do allocate memory..
		DisposeRoutineDescriptor(myDlgHookUPP);
		*documentFSSpec = mySFR.sfFile; 
		return !mySFR.sfGood;
	}
#endif
#if !MINIMALVM
    //  Specify default options for dialog box
    anErr = NavGetDefaultDialogOptions(&dialogOptions);
    if (anErr == noErr)
    {
        //  Adjust the options to fit our needs
        //  Set default location option
        //  dialogOptions.dialogOptionFlags |= kNavSelectDefaultLocation;
        dialogOptions.dialogOptionFlags |= kNavAllFilesInPopup;
        dialogOptions.dialogOptionFlags |= kNavSelectAllReadableItem;
        //  Clear preview option
        dialogOptions.dialogOptionFlags ^= kNavAllowPreviews;
        
        // make descriptor for default location
        anErr = AECreateDesc(typeFSS, defaultLocationfssPtr,
                             sizeof(*defaultLocationfssPtr),
                             &defaultLocation );
        if (anErr == noErr)
        {
            // Get 'open' resource. A nil handle being returned is OK,
            // this simply means no automatic file filtering.
            // 3.2.1, use filter proc, not open resource, because of os-x tag, metadata issues
            NavTypeListHandle typeList = nil;
            // NavTypeListHandle typeList = (NavTypeListHandle)GetResource('open', 128);
            
            NavReplyRecord reply;
            
            // Call NavGetFile() with specified options and
            // declare our app-defined functions and type list
            anErr = NavGetFile (&defaultLocation, &reply, &dialogOptions,
                                eventProc, nil, filterProc,
                                typeList, nil);
            if (anErr == noErr && reply.validRecord)
            {
                //  Deal with multiple file selection
                long    count;
                
                anErr = AECountItems(&(reply.selection), &count);
                // Set up index for file list
                if (anErr == noErr)
                {
                    long index;
                    
                    for (index = 1; index <= 1; index++)
                    {
                        AEKeyword   theKeyword;
                        DescType    actualType;
                        Size        actualSize;
                        
                        // Get a pointer to selected file
                        anErr = AEGetNthPtr(&(reply.selection), index,
                                            typeFSS, &theKeyword,
                                            &actualType,documentFSSpec,
                                            sizeof(FSSpec),
                                            &actualSize);
                     }
                }
                //  Dispose of NavReplyRecord, resources, descriptors
                anErr = NavDisposeReply(&reply);
            }
            if (typeList != nil)
            {
                ReleaseResource( (Handle)typeList);
            }
            (void) AEDisposeDesc(&defaultLocation);
        }
    }
    DisposeNavEventUPP(eventProc);
    DisposeNavObjectFilterUPP(filterProc);
    return anErr;
#endif
}

pascal void findImageEventProc(NavEventCallbackMessage callBackSelector, 
                        NavCBRecPtr callBackParms, 
                        NavCallBackUserData callBackUD)
{
#pragma unused(callBackUD)
   // WindowPtr window = 
   //                 (WindowPtr)callBackParms->eventData.event->message;
    switch (callBackSelector)
    {
        case kNavCBEvent:
            switch (((callBackParms->eventData)
                    .eventDataParms).event->what)
            {
                case updateEvt:
                   // MyHandleUpdateEvent(window, 
                    //    (EventRecord*)callBackParms->eventData.event);
                    break;
            }
            break;
    }
}

pascal Boolean findImageFilterProc(AEDesc* theItem, void* info, 
                            NavCallBackUserData callBackUD,
                            NavFilterModes filterMode)
{
#pragma unused(filterMode,callBackUD)
    NavFileOrFolderInfo* theInfo = (NavFileOrFolderInfo*)info;
    
    if (theItem->descriptorType == typeFSS) {
        char checkSuffix[256];
        FSSpec	theSpec;
        OSErr 	error;
        Boolean check;
        
        if (theInfo->isFolder)
            return true;
            
        if (theInfo->fileAndFolder.fileInfo.finderInfo.fdType == 'STim')
            return true;
            
        error = AEGetDescData(theItem,&theSpec,sizeof(theSpec));
        if (error != noErr) 
            return true;
        
        CopyPascalStringToC(theSpec.name,checkSuffix);
        check = IsImageName(checkSuffix);
        if (check) 
            return true;
        else
            return false;
    }
    return true;
}

#if !TARGET_API_MAC_CARBON

// this dialog hook for System 7 std file selects
// the file specified by the hookRecord supplied as userData

pascal short DialogHook(short item, DialogPtr theDialog, 
	void *userData)
{
	HookRecordPtr hookRecPtr;
	
	hookRecPtr = (HookRecordPtr) userData;
	
	// hookRecPtr->itemSpec points to the FSSpec of the item to be selected
	// hookRecPtr->theSFR points to the standard file reply record

	// make sure we're dealing with the proper dialog
	if (GetWRefCon(theDialog) == sfMainDialogRefCon) {
	
		// just when opening the dialog...
		if (item == sfHookFirstCall) {
	
			// make the reply record hold the spec of the specified item
			hookRecPtr->theSFR->sfFile = *hookRecPtr->itemSpec;
			
			// ThereÕs a gotcha in Standard File when using sfHookChangeSelection. 
			// Even though New Inside Macintosh: Files has a sample that doesn't set
			// the sfScript field, it should be set, or the last object in the
			// selected directory  will always be selected.
			hookRecPtr->theSFR->sfScript = smSystemScript;

			// tell std file to change the selection to that item
			item = sfHookChangeSelection;
		}
	}			
		
	return item;
}

#endif


/* 
 Some trial code, to keep for now, must delete some day

            err = makeFSSpec((char *) src,num,&convertFileNameSpec);
            if ((err == noErr) && resolveAlias)
                err = ResolveAliasFile(&convertFileNameSpec,true,&isFolder,&isAlias);
                
            err = FSpMakeFSRef(&convertFileNameSpec,&theFSRef);
            if (err == fnfErr) {
                failureRetry = convertFileNameSpec;
                CopyCStringToPascal(":",failureRetry.name);
                err = FSpMakeFSRef(&failureRetry,&theFSRef);
                if (err != noErr) 
                    return;
                err = FSRefMakePath(&theFSRef,(UInt8 *) dst,1000); 
                if (err != noErr) 
                    return;
                if (dst[strlen(dst)-1] != ':')
                strcat(dst,"/");
                CopyPascalStringToC(convertFileNameSpec.name,(char *)convertFileNameSpec.name);
                strcat(dst,(char *)convertFileNameSpec.name);
                return;
            }
            err = FSRefMakePath(&theFSRef,(UInt8 *)dst,1000); 

int fetchFileInfo(CInfoPBRec *pb,int dirIndex,FSSpec *spec,unsigned char *name,Boolean doAlias,Boolean *isFolder) {
    OSErr		error;
    FSCatalogInfo 	catalogInfo;
    HFSUniStr255 	unicodeName;
    LocalDateTime 	localDateTime;
    CFStringRef 	theString;
    ItemCount		actualObjects;
    FSSpec		currentFSSpec;
    static FSSpec 	rememberCurrentSpec;
    static int 	  	rememberLastDirIndex=-32768;
    static FSRef  	theFSRef;
    static FSIterator 	theIterator;
    static Boolean 	interatorInitialized=false;
    
    if (!(memcmp(&rememberCurrentSpec,(char *) spec,sizeof(FSSpec)) == 0) 
        || (++rememberLastDirIndex != dirIndex)) {
        if (interatorInitialized) {
            FSCloseIterator(theIterator);
            interatorInitialized = false;
        }
        error = FSpMakeFSRef (spec, &theFSRef);
        if (error != noErr) 
            return false;
        error = FSOpenIterator(&theFSRef, kFSIterateFlat, &theIterator);
        if (error != noErr) 
            return false;
        interatorInitialized = true;
        rememberLastDirIndex = dirIndex;
        rememberCurrentSpec = *spec;
    }
    
     error = FSGetCatalogInfoBulk(theIterator,1,&actualObjects,nil,
            kFSCatInfoNodeFlags+kFSCatInfoCreateDate+kFSCatInfoContentMod+kFSCatInfoDataSizes+kFSCatInfoFinderInfo,
            &catalogInfo,nil,&currentFSSpec,&unicodeName);
             
    if (error != noErr) 
        return false;

    memcpy(&pb->hFileInfo.ioFlFndrInfo,catalogInfo.finderInfo,sizeof(FInfo));
    if ((pb->hFileInfo.ioFlFndrInfo.fdFlags & kIsAlias) && doAlias) {
        Boolean isAlias;
        OSErr   err;
		    
        if (((Ptr) ResolveAliasFileWithMountFlags != (Ptr)kUnresolvedCFragSymbolAddress)) {
            err = ResolveAliasFileWithMountFlags(&currentFSSpec,false,isFolder,&isAlias,kResolveAliasFileNoUI);
            } 
        else 
            err = ResolveAliasFile(&currentFSSpec,false,isFolder,&isAlias);    		
    			
       if (err == noErr) {
            if (dirIndex == 0) {
                fetchFileInfo(pb,dirIndex,&currentFSSpec,name,false,isFolder);
                *spec = currentFSSpec;
                return true;
            }
            error = FSpMakeFSRef (&currentFSSpec, &theFSRef);
            if (error != noErr) 
                return false;
            error = FSGetCatalogInfo(&theFSRef,
                kFSCatInfoNodeFlags+kFSCatInfoCreateDate+kFSCatInfoContentMod
                +kFSCatInfoDataSizes+kFSCatInfoFinderInfo,
                &catalogInfo,&unicodeName,&currentFSSpec,nil);
            if (error != noErr) 
                return false;
                
        }
    }  
    ConvertUTCToLocalDateTime(&catalogInfo.createDate,&localDateTime); 
    pb->hFileInfo.ioFlCrDat = localDateTime.lowSeconds;
    ConvertUTCToLocalDateTime(&catalogInfo.contentModDate,&localDateTime); 
    pb->hFileInfo.ioFlMdDat = localDateTime.lowSeconds;
    memcpy(&pb->hFileInfo.ioFlFndrInfo,catalogInfo.finderInfo,sizeof(FInfo));
    pb->hFileInfo.ioFlAttrib = 0;
    *isFolder = false;
    if (catalogInfo.nodeFlags & kFSNodeIsDirectoryMask) {
        pb->hFileInfo.ioFlAttrib = kioFlAttribDirMask;
        *isFolder = true;
    }
        
    pb->hFileInfo.ioFlLgLen = catalogInfo.dataLogicalSize; 
    theString = CFStringCreateWithCharacters (nil, unicodeName.unicode, (CFIndex) unicodeName.length);
    CFStringGetCString (theString,name,256, gCurrentVMEncoding);
    CopyCStringToPascal(name,name);
    CFRelease(theString);

    return true;
}
*/
