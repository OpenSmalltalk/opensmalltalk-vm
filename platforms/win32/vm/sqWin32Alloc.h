#ifndef __SQ_WIN32_ALLOC_H
#define __SQ_WIN32_ALLOC_H

#ifndef NO_VIRTUAL_MEMORY

/* use a maximum of 16 MB if nothing else is defined*/
#ifndef MAX_VIRTUAL_MEMORY
#define MAX_VIRTUAL_MEMORY 16
#endif

/* Memory initialize-release */
#undef sqAllocateMemory
#undef sqGrowMemoryBy
#undef sqShrinkMemoryBy
#undef sqMemoryExtraBytesLeft

void *sqAllocateMemory(int minHeapSize, int desiredHeapSize);
int sqGrowMemoryBy(int oldLimit, int delta);
int sqShrinkMemoryBy(int oldLimit, int delta);
int sqMemoryExtraBytesLeft(int includingSwap);

void sqReleaseMemory(void);

#endif /* NO_VIRTUAL_MEMORY */
#endif /* __SQ_WIN32_ALLOC_H */
