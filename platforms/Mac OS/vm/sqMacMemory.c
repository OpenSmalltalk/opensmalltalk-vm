/****************************************************************************
*   PROJECT: Mac allocate memory from somewhere for the image
*   FILE:    sqMacMemory.c
*   CONTENT: 
*
*   AUTHOR:  John Maloney, John McIntosh, and others.
*   ADDRESS: 
*   EMAIL:   johnmci@smalltalkconsulting.com
*   RCSID:   $Id: sqMacMemory.c,v 1.13 2004/04/23 20:47:15 johnmci Exp $
*
*   NOTES: 
*  Feb 22nd, 2002, JMM moved code into 10 other files, see sqMacMain.c for comments
*  Mar  8th, 2002, JMM Must unmap view first then free.
*  3.2.8b1 July 24th, 2002 JMM support for os-x plugin under IE 5.x
*  3.5.1b5 June 25th, 2003 JMM get memory upper limit from os-x user preferences
*****************************************************************************/

#include "sq.h" 
#include "sqMacMemory.h"
#include "sqMacMain.h"

#if defined ( __APPLE__ ) && defined ( __MACH__ )
#include <sys/mman.h>
#endif

extern UInt32  gMaxHeapSize;
UInt32	gHeapSize;
Boolean	gNoFileMappingInOS9=false;

/* compute the desired memory allocation */
#ifdef JITTER
const long	reservedMemory = 1000000;
#else
	#ifdef MINIMALVM
	const long		reservedMemory = 128000;
	#else
	const long		reservedMemory = 500000;
	#endif
#endif


extern unsigned char *memory;

#if !TARGET_API_MAC_CARBON
	#include <FileMapping.h>
	BackingFileID gBackingFile=0;
	FileViewID gFileViewID=0;
#endif

Boolean hasFileMapping(void);
Boolean isSystem9_2_or_better(void);
UInt32	sqGetAvailableMemory() {

	long 	availableMemory;
	
#if TARGET_API_MAC_CARBON && defined(__MWERKS__)
    availableMemory = MaxBlock() - reservedMemory;
    return availableMemory;
#endif 

#if TARGET_API_MAC_CARBON
	availableMemory = gMaxHeapSize;
#else
	availableMemory = MaxBlock() - reservedMemory;
	if ((availableMemory > 128*1024*1024) || !isSystem9_2_or_better())
		gNoFileMappingInOS9 = true;
	else
		if (hasFileMapping() && 
			((Ptr)OpenMappedScratchFile != (Ptr)kUnresolvedCFragSymbolAddress)) {
    			gMaxHeapSize = 128*1024*1024;
	   			availableMemory = gMaxHeapSize;
		}
#endif

	/******
	  Note: This is platform-specific. On the Mac, the user specifies the desired
	    memory partition for each application using the Finder's Get Info command.
	    MaxBlock() returns the amount of memory in the partition minus space for
	    the code segment and other resources. On other platforms, the desired heap
	    size would be specified in other ways (e.g, via a command line argument).
	    The maximum size of the object heap is fixed at at startup. If you run low
	    on space, you must save the image and restart with more memory.

	  Note: Some memory must be reserved for Mac toolbox calls, sound buffers, etc.
	    A 30K reserve is too little. 40K allows Squeak to run but crashes if the
	    console is opened. 50K allows the console to be opened (with and w/o the
	    profiler). I added another 30K to provide for sound buffers and reliability.
	    (Note: Later discovered that sound output failed if SoundManager was not
	    preloaded unless there is about 100K reserved. Added 50K to that.)
	    
	    JMM Note changed to 500k for Open Transport support on 68K machines
	    
	    For os-x this doesn't matter we just mmap 512MB for the image, and 
	    the application allocates more out of the 4GB address for VM logic. 
	    
	    For os-9 we attempt to use mapped scratch files if we are a classic app.
	    This requires support under os-9, also it doesn't work under os-x so the 
	    logic above is a bit convoluted.
	******/

	return availableMemory;
}

void * sqAllocateMemoryMac(int minHeapSize, int *desiredHeapSize) {
    void * debug;
    OSErr err;
	minHeapSize;
     
#if (TARGET_API_MAC_CARBON && defined(__MWERKS__))
    gMaxHeapSize = gHeapSize = *desiredHeapSize;
    
    #if TARGET_API_MAC_CARBON
	    return NewPtr(*desiredHeapSize);
    #else
        debug = NewPtr(*desiredHeapSize);
        if (debug == null) 
	       return NewPtrSys(*desiredHeapSize);
	    else 
	      return debug;
    #endif
#else
#if TARGET_API_MAC_CARBON
    gHeapSize = gMaxHeapSize;
    debug = mmap( NULL, gMaxHeapSize, PROT_READ | PROT_WRITE, MAP_ANON | MAP_SHARED,-1,0);
    if((debug == MAP_FAILED) || (((long) debug) < 0))
        return 0;
    return debug;
#else
    if(((Ptr)OpenMappedScratchFile != (Ptr)kUnresolvedCFragSymbolAddress) && hasFileMapping() && !gNoFileMappingInOS9) {
        ByteCount  viewLength;
        long       i;
        
        err = 1;
        for(i=gMaxHeapSize;i>minHeapSize;i-=8*1024*1024) {
            *desiredHeapSize = gHeapSize = i;
            err = OpenMappedScratchFile(kFSInvalidVolumeRefNum,gHeapSize,kCanReadMappedFile|kCanWriteMappedFile,&gBackingFile);
            if (err == noErr) 
                break;
        }
        if (err != noErr)
            goto fallBack;
	          
        err = MapFileView(gBackingFile, NULL, kMapEntireFork,kFileViewAccessReadWrite,0, kNilOptions, &debug, &viewLength, &gFileViewID);
        if (err != noErr)
            goto fallBack;
        return debug;
    } 
    
fallBack:
    if (gNoFileMappingInOS9)
        gHeapSize = gMaxHeapSize = *desiredHeapSize;
    else
        gHeapSize = gMaxHeapSize = MaxBlock() - reservedMemory*2;
        
    if (gHeapSize < minHeapSize) 
    	return 0;
    *desiredHeapSize = gHeapSize;
	debug = NewPtr(gHeapSize);
	return debug;
#endif 
#endif
}

int sqGrowMemoryBy(int memoryLimit, int delta) {
    if (memoryLimit + delta - (int) memory > gMaxHeapSize)
        return memoryLimit;
   
    gHeapSize += delta;
    return memoryLimit + delta;
}

int sqShrinkMemoryBy(int memoryLimit, int delta) {
    return sqGrowMemoryBy(memoryLimit,0-delta);
}

int sqMemoryExtraBytesLeft(Boolean flag) {
    if (flag) 
        return gMaxHeapSize - gHeapSize;
    else
        return 0;
}

void sqMacMemoryFree() {
	if (memory == nil) 
		return;
#if TARGET_API_MAC_CARBON
    #ifdef BROWSERPLUGIN
    munmap((void *) memory,gMaxHeapSize);
    #endif
#else
    if(((Ptr)OpenMappedScratchFile != (Ptr)kUnresolvedCFragSymbolAddress) && (gBackingFile != 0)) {       
	    OSErr	error;
		error = UnmapFileView(gFileViewID);
		error = CloseMappedFile(gBackingFile);
        gBackingFile = 0;
    } else {
			DisposePtr((void *) memory);
    }
#endif

	memory = nil;
}

Boolean hasFileMapping(void)
{
    UInt32	response;
    OSErr	error;
    
    error = Gestalt(gestaltFileMappingAttr, 
                    (SInt32 *) &response);
    return ((error == noErr)
                && response);
}

Boolean isSystem9_2_or_better(void)
{
    UInt32	response;
    OSErr	error;
    
    error = Gestalt(gestaltSystemVersion, 
                    (SInt32 *) &response);
    return ((error == noErr)
                && (response >= 0x0920));
}

