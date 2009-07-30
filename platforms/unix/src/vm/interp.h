/* Automatically generated from Squeak on an Array(29 July 2009 10:58:55 pm)
by VMMaker 3.10.7
 */

#define SQ_VI_BYTES_PER_WORD 4

#ifndef allocateMemoryMinimumImageFileHeaderSize
 /* Called by Interpreter>>allocateMemory:minimum:imageFile:headerSize: */
 #define allocateMemoryMinimumImageFileHeaderSize(heapSize, minimumMemory, fileStream, headerSize) \
    sqAllocateMemory(minimumMemory, heapSize)
#endif

#ifndef sqImageFileReadEntireImage
 /* Called by Interpreter>>sqImage:read:size:length: */
 #define sqImageFileReadEntireImage(memoryAddress, elementSize,  length, fileStream) \
    sqImageFileRead(memoryAddress, elementSize,  length, fileStream)
#endif

