/****************************************************************************
*   PROJECT: Mac allocate memory from somewhere for the image
*   FILE:    sqMacMemory.c
*   CONTENT: 
*
*   AUTHOR:  John Maloney, John McIntosh, and others.
*   ADDRESS: 
*   EMAIL:   johnmci@smalltalkconsulting.com
*   RCSID:   $Id: sqMacMemory.c,v 1.2 2002/02/23 11:25:47 johnmci Exp $
*
*   NOTES: 
*  Feb 22nd, 2002, JMM moved code into 10 other files, see sqMacMain.c for comments
*****************************************************************************/

#include "sq.h" 
#include "sqMacMemory.h"

#if defined ( __APPLE__ ) && defined ( __MACH__ )
#include <sys/mman.h>
#endif

unsigned long  gMaxHeapSize=512*1024*1024;

extern unsigned char *memory;
unsigned long	gHeapSize;
#if !TARGET_API_MAC_CARBON
#include <FileMapping.h>
BackingFileID gBackingFile=0;
FileViewID gFileViewID=0;
#endif

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
/*     This should work under os-9 but has problems I've yet not debugged

    if((Ptr)OpenMappedScratchFile != (Ptr)kUnresolvedCFragSymbolAddress) {
        ByteCount  viewLength;
        long       i;
        
        for(i=gMaxHeapSize;i>desiredHeapSize;i-=50*1024*1024) {
            gHeapSize = gMaxHeapSize = i;
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
    } */
    
    
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
#if TARGET_API_MAC_CARBON
   /* if (delta < 0) {
        long range,start,check;
        
        range = gMaxHeapSize - gHeapSize;
        start = memoryLimit + delta + 4096;
        range = 4096;
        if (start < gMaxHeapSize) 
            check = madvise(trunc_page(start),round_page(range),MADV_DONTNEED);
        if (check == -1) 
            check = errno;
    } */
#endif
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

