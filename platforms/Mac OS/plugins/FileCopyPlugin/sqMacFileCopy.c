/* Use the extra files logic from Apple to copy a directory or file to another directory or file  */
//John M McIntosh johnmci@smalltalkconsulting.com Aug 21 2001 Chunnel build

#include <string.h>
#include "FileCopy.h"
#include "FullPath.h"
#include "DirectoryCopy.h"
#include "MoreFilesExtras.h"
#include "FSpCompat.h"
#include "sqMacFileCopy.h"


int sqCopyFilesizetosize(char *srcNameIndex, int srcNameSize, char *dstNameIndex, int dstNameSize) {

	OSErr error;
	FSSpec	srcSpec,dstFileSpec,dstSpec;
	char *pointer;
	const int desiredBufferSize = 64*1024;

	FSpLocationFromFullPath(srcNameSize,srcNameIndex,&srcSpec);
	FSpLocationFromFullPath(dstNameSize,dstNameIndex,&dstFileSpec);
	FSMakeFSSpecCompat(dstFileSpec.vRefNum, dstFileSpec.parID, "\p:", &dstSpec);
#if TARGET_API_MAC_CARBON
		pointer = NewPtr(desiredBufferSize);
#else
	    pointer = NewPtr(desiredBufferSize);
	    if (pointer == NULL) 
		    pointer = NewPtrSys(desiredBufferSize);
	    if (pointer == NULL) 
  			return false;
 #endif
	error = FSpFileCopy(&srcSpec,
						&dstSpec,
						dstFileSpec.name,
						pointer,
						desiredBufferSize,
						false);
	DisposePtr((void *)pointer);
	return error;
} 

int sqCopyDirectorysizetosize(char *srcNameIndex, int srcNameSize, char *dstNameIndex, int dstNameSize) {

	OSErr error;
	FSSpec	srcSpec,dstSpec,dstFolderSpec;
	char *pointer;
	const int desiredBufferSize = 64*1024;
    char name[256];

	memmove(name,srcNameIndex,srcNameSize);
	memmove(name+srcNameSize,":",1);
	FSpLocationFromFullPath(srcNameSize+1,name,&srcSpec);
	memmove(name,dstNameIndex,dstNameSize);
	memmove(name+dstNameSize,":",1);
	FSpLocationFromFullPath(dstNameSize+1,name,&dstFolderSpec);
	FSMakeFSSpecCompat(dstFolderSpec.vRefNum, dstFolderSpec.parID, "\p:", &dstSpec);

#if TARGET_API_MAC_CARBON
		pointer = NewPtr(desiredBufferSize);
#else
	    pointer = NewPtr(desiredBufferSize);
	    if (pointer == NULL) 
		    pointer = NewPtrSys(desiredBufferSize);
	    if (pointer == NULL) 
  			return false;
 #endif
    memmove(name,dstFolderSpec.name,sizeof(dstFolderSpec.name));
	error = FSpDirectoryCopy(&srcSpec,
						&dstSpec,
						(ConstStr255Param) &name,
						pointer,
						desiredBufferSize,
						false,
						&handleDupError);

	DisposePtr((void *)pointer);
	return error;
} 


pascal Boolean handleDupError(OSErr error,
					short failedOperation,
					short srcVRefNum,
					long srcDirID,
					ConstStr255Param srcName,
					short dstVRefNum,
					long dstDirID,
					ConstStr255Param dstName)
{
 if (error == dupFNErr ) 
	return false;
  return true; 
}