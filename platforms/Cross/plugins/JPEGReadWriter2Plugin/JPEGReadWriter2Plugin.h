#include <stdio.h>
/* Interface to JPEG code */
#include "jpeglib.h"
#include <setjmp.h>

struct error_mgr2 {
  struct jpeg_error_mgr pub;	/* "public" fields */

  jmp_buf setjmp_buffer;	/* for return to caller */
};

typedef struct error_mgr2* error_ptr2;

void error_exit (j_common_ptr cinfo);
