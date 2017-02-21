#include <stdio.h>
/* Interface to JPEG code */
#include "jpeglib.h"
#include <setjmp.h>

struct error_mgr2 {
  struct jpeg_error_mgr pub;	/* "public" fields */

  jmp_buf *setjmp_buffer;	/* for return to caller */
};

typedef struct error_mgr2* error_ptr2;

void error_exit (j_common_ptr cinfo);
GLOBAL(void) jpeg_mem_src (j_decompress_ptr cinfo, char * pSourceData, unsigned sourceDataSize);
GLOBAL(int) jpeg_mem_src_newLocationOfData (j_decompress_ptr cinfo, char * pSourceData, unsigned sourceDataSize);
GLOBAL(void) jpeg_mem_dest (j_compress_ptr cinfo, char * pDestination, unsigned *pDestinationSize);
void primJPEGWriteImageonByteArrayformqualityprogressiveJPEGerrorMgrWriteScanlines(
    unsigned int, 
    unsigned int, 
    int,
    unsigned int*,
    char*,
    char*,
    int,
    int, 
    unsigned int, 
    unsigned int,
    char*,
    unsigned int*);

void primJPEGReadImagefromByteArrayonFormdoDitheringerrorMgrReadScanlines(
    char*,
    char*,
    char*,
    unsigned int,
    int,
    unsigned int*,
    unsigned int,
    unsigned int,
    int);

void primJPEGReadHeaderfromByteArraysizeerrorMgrReadHeader(
    char*,
    char*,
    unsigned int,
    char*);
