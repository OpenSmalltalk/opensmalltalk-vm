/****************************************************************************
*   PROJECT: Mac allocate memory from somewhere for the image
*   FILE:    sqMacMemory.c
*   CONTENT: 
*
*   AUTHOR:  John Maloney, John McIntosh, and others.
*   ADDRESS: 
*   EMAIL:   johnmci@smalltalkconsulting.com
*   RCSID:   $Id: sqMacMemory.c,v 1.3 2002/03/04 00:30:57 johnmci Exp $
*
*   NOTES: 
*  Feb 22nd, 2002, JMM moved code into 10 other files, see sqMacMain.c for comments
*****************************************************************************/

#include "sq.h" 
#include "sqMacMemory.h"
#include "sqMacMain.h"

#if defined ( __APPLE__ ) && defined ( __MACH__ )
#include <sys/mman.h>
#endif

UInt32  gMaxHeapSize=512*1024*1024;
UInt32	gHeapSize;
Boolean	gNoFileMappingInOS9=false;

extern unsigned char *memory;

#if !TARGET_API_MAC_CARBON
	#include <FileMapping.h>
	BackingFileID gBackingFile=0;
	FileViewID gFileViewID=0;
#endif

UInt32	sqGetAvailableMemory() {

	long 	reservedMemory,availableMemory;

/* compute the desired memory allocation */
#ifdef JITTER
	reservedMemory = 1000000;
#else
#ifdef MINIMALVM
	reservedMemory = 128000;
#else
	reservedMemory = 500000;
#endif
#endif

#if TARGET_API_MAC_CARBON
	availableMemory = gMaxHeapSize;
#else
	availableMemory = MaxBlock() - reservedMemory;
	if (availableMemory > 128*1024*1024) 
		gNoFileMappingInOS9 = true;
	else
		if (!RunningOnCarbonX() && 
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

void * sqAllocateMemory(int minHeapSize, int desiredHeapSize) {
    void * debug;
    OSErr err;
	minHeapSize;
     
#ifdef PLUGIN
    gMaxHeapSize = gHeapSize = desiredHeapSize;
    
    #if TARGET_API_MAC_CARBON
	    return NewPtr(desiredHeapSize);
    #else
        pointer = NewPtr(desiredHeapSize);
        if (pointer == null) 
	       return NewPtrSys(desiredHeapSize);
	    else 
	      return pointer;
    #endif
#endif

#if TARGET_API_MAC_CARBON
    gHeapSize = gMaxHeapSize;
    debug = mmap( NULL, gMaxHeapSize, PROT_READ | PROT_WRITE, MAP_ANON | MAP_SHARED,-1,0);
    if((debug == MAP_FAILED) || (((long) debug) < 0))
        return 0;
    return debug;
#else
    if(((Ptr)OpenMappedScratchFile != (Ptr)kUnresolvedCFragSymbolAddress) && !RunningOnCarbonX() && !gNoFileMappingInOS9) {
        ByteCount  viewLength;
        long       i;
        
        err = 1;
        for(i=gMaxHeapSize;i>=desiredHeapSize;i-=8*1024*1024) {
            gHeapSize = i;
            err = OpenMappedScratchFile(kFSInvalidVolumeRefNum,i,kCanReadMappedFile|kCanWriteMappedFile,&gBackingFile);
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
    gHeapSize = gMaxHeapSize = desiredHeapSize;
	debug = NewPtr(desiredHeapSize);
	return debug;
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
#else
    if(((Ptr)OpenMappedScratchFile != (Ptr)kUnresolvedCFragSymbolAddress) && (gBackingFile != 0)) {
        CloseMappedFile(gBackingFile);
        gBackingFile = 0;
    } else {
		if (memory != nil)
			DisposePtr((void *) memory);
    }
#endif

	memory = nil;
}