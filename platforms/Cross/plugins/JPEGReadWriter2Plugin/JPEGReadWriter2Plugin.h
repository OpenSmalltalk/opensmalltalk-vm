/* Interface to JPEG code */
#include <setjmp.h>
#include "sqSetjmpShim.h"
#include "jpeglib.h"

typedef struct error_mgr2 {
  struct jpeg_error_mgr pub;	/* "public" fields */

  jmp_buf *setjmp_buffer;	/* for return to caller */
} *error_ptr2;

void error_exit (j_common_ptr cinfo);
GLOBAL(void) jpeg_mem_src (j_decompress_ptr cinfo, unsigned char * pSourceData, unsigned sourceDataSize);
GLOBAL(int) jpeg_mem_src_newLocationOfData (j_decompress_ptr cinfo, unsigned char * pSourceData, unsigned sourceDataSize);
GLOBAL(void) jpeg_mem_dest (j_compress_ptr cinfo, unsigned char * pDestination, unsigned *pDestinationSize);
void primJPEGWriteImageonByteArrayformqualityprogressiveJPEGerrorMgrWriteScanlines(
    unsigned int, 
    unsigned int, 
    int,
    unsigned int *,
    unsigned char *,
    unsigned char *,
    int,
    int, 
    unsigned int, 
    unsigned int,
    unsigned char *,
    unsigned int *);

void primJPEGReadImagefromByteArrayonFormdoDitheringerrorMgrReadScanlines(
    unsigned char *,
    unsigned char *,
    unsigned char *,
    unsigned int,
    int,
    unsigned int *,
    unsigned int,
    unsigned int,
    int);

void primJPEGReadHeaderfromByteArraysizeerrorMgrReadHeader(
    unsigned char *,
    unsigned char *,
    unsigned int,
    unsigned char *);
