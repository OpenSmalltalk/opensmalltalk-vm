#include <stdio.h>
#include "jpeglib.h"
#include <setjmp.h>

struct error_mgr2 {
  struct jpeg_error_mgr pub;	/* "public" fields */

  jmp_buf *setjmp_buffer;	/* for return to caller */
};

typedef struct error_mgr2 * error_ptr2;

/*
 * Here's the routine that will replace the standard error_exit method:
 */

void error_exit (j_common_ptr cinfo)
{
  /* cinfo->err really points to a error_mgr2 struct, so coerce pointer */
  error_ptr2 myerr = (error_ptr2) cinfo->err;

  /* Return control to the setjmp point */
  longjmp(*myerr->setjmp_buffer, 1);
}
